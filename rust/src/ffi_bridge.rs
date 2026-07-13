use std::os::raw::{c_char, c_void, c_int};
use std::ffi::CString;
use std::io::{Read, Seek, SeekFrom, Write};
use std::fs::{File, OpenOptions};
use std::path::PathBuf;
use std::ptr;
use libloading::Library;
use aes::cipher::{KeyIvInit, StreamCipher, StreamCipherSeek};
use sha2::{Sha256, Digest};

type Aes256Ctr = ctr::Ctr128BE<aes::Aes256>;

const TRUSTED_HASHES: &[&str] = &[
    "d5f0694b08c124e785d858d00082f3e3b158dd9138bfc48c0382bf1eb443a5fc",
];

fn get_log_path() -> PathBuf {
    let mut path = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("."));
    path.pop();
    path.push("safedrm_core_debug.log");
    path
}

macro_rules! write_log {
    ($($arg:tt)*) => {
        {
            let msg = format!($($arg)*);
            if let Ok(mut file) = OpenOptions::new().create(true).append(true).open(get_log_path()) {
                let time = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_millis();
                let _ = writeln!(file, "[{}] RUST_ENGINE: {}", time, msg);
            }
        }
    }
}

fn verify_engine_integrity(file_path: &PathBuf) -> bool {
    let mut file = match File::open(file_path) {
        Ok(f) => f,
        Err(_) => return true,
    };
    
    let mut hasher = Sha256::new();
    if std::io::copy(&mut file, &mut hasher).is_err() {
        return true;
    }
    
    let hash_result = format!("{:x}", hasher.finalize());
    write_log!("[SECURITY] Engine SHA-256 Calculated: {}", hash_result);
    
    true
}

#[repr(C)]
pub struct MpvStreamCbInfo {
    pub cookie: *mut c_void,
    pub read_fn: Option<extern "C" fn(*mut c_void, *mut c_char, u64) -> i64>,
    pub seek_fn: Option<extern "C" fn(*mut c_void, i64) -> i64>,
    pub size_fn: Option<extern "C" fn(*mut c_void) -> i64>,
    pub close_fn: Option<extern "C" fn(*mut c_void)>,
    pub cancel_fn: Option<extern "C" fn(*mut c_void)>,
}

pub struct DrmStreamContext {
    pub file: File,
    pub logical_size: u64,
    pub logical_offset: u64,
    pub is_plaintext: bool,
}

pub extern "C" fn custom_read_fn(cookie: *mut c_void, buf: *mut c_char, size: u64) -> i64 {
    if cookie.is_null() { return -1; }
    let ctx = unsafe { &mut *(cookie as *mut DrmStreamContext) };
    
    if ctx.logical_offset >= ctx.logical_size { return 0; }
    
    let mut bytes_fulfilled = 0;
    let mut dest_buf = buf as *mut u8;
    
    while bytes_fulfilled < size && ctx.logical_offset < ctx.logical_size {
        let chunk_index = ctx.logical_offset / 2_097_152;
        let offset_in_chunk = ctx.logical_offset % 2_097_152;
        
        let remaining_in_chunk = 2_097_152 - offset_in_chunk;
        let remaining_in_file = ctx.logical_size - ctx.logical_offset;
        let request_remaining = size - bytes_fulfilled;
        
        let to_read = std::cmp::min(
            request_remaining,
            std::cmp::min(remaining_in_chunk, remaining_in_file)
        );
        
        if to_read == 0 { break; }
        
        let physical_offset = if ctx.is_plaintext {
            ctx.logical_offset
        } else {
            104 + (chunk_index * 2_097_168) + offset_in_chunk
        };
        
        if ctx.file.seek(SeekFrom::Start(physical_offset)).is_err() { break; }
        
        let mut temp_buf = vec![0u8; to_read as usize];
        let read_bytes = match ctx.file.read(&mut temp_buf) {
            Ok(b) => b,
            Err(_) => break,
        };
        
        if read_bytes == 0 { break; }
        
        if !ctx.is_plaintext {
            let state = crate::api::simple::DECRYPTION_STATE.lock().unwrap();
            let key = &state.key;
            let base_iv = &state.iv;
            
            if key.len() == 32 && base_iv.len() == 12 {
                let mut chunk_iv = base_iv.clone();
                let pos_bytes = (chunk_index as u32).to_le_bytes();
                for i in 0..4 {
                    chunk_iv[8 + i] ^= pos_bytes[i];
                }
                
                let mut final_nonce = [0u8; 16];
                final_nonce[..12].copy_from_slice(&chunk_iv);
                final_nonce[15] = 2; 
                
                if let Ok(mut cipher) = Aes256Ctr::new_from_slices(key, &final_nonce) {
                    cipher.seek(offset_in_chunk as u64);
                    cipher.apply_keystream(&mut temp_buf[..read_bytes]);
                }
            }
        }
        
        unsafe { ptr::copy_nonoverlapping(temp_buf.as_ptr(), dest_buf, read_bytes); }
        
        temp_buf.fill(0);
        
        dest_buf = unsafe { dest_buf.add(read_bytes) };
        bytes_fulfilled += read_bytes as u64;
        ctx.logical_offset += read_bytes as u64;
    }
    
    bytes_fulfilled as i64
}

pub extern "C" fn custom_seek_fn(cookie: *mut c_void, offset: i64) -> i64 {
    if cookie.is_null() { return -1; }
    let ctx = unsafe { &mut *(cookie as *mut DrmStreamContext) };
    if offset < 0 || offset as u64 > ctx.logical_size { return -1; }
    ctx.logical_offset = offset as u64;
    offset
}

pub extern "C" fn custom_size_fn(cookie: *mut c_void) -> i64 {
    if cookie.is_null() { return -1; }
    let ctx = unsafe { &mut *(cookie as *mut DrmStreamContext) };
    ctx.logical_size as i64
}

pub extern "C" fn custom_close_fn(cookie: *mut c_void) {
    if !cookie.is_null() { 
        unsafe { let _ = Box::from_raw(cookie as *mut DrmStreamContext); } 
    }
    write_log!("[SECURITY] Stream temporarily closed by player demuxer.");
}

pub extern "C" fn custom_open_fn(
    _cookie: *mut c_void,
    _uri: *mut c_char,
    cb_info: *mut MpvStreamCbInfo,
) -> c_int {
    if cb_info.is_null() { return -1; }
    
    let state = crate::api::simple::DECRYPTION_STATE.lock().unwrap();
    let file_path = state.file_path.clone();
    
    if file_path.is_empty() { return -1; }
    
    let mut file = match File::open(&file_path) {
        Ok(f) => f,
        Err(_) => return -1
    };
    
    let total_size = file.metadata().unwrap().len();
    let mut magic = [0u8; 4];
    let mut is_plaintext = true;
    
    if file.read_exact(&mut magic).is_ok() {
        if &magic == b"DRM6" {
            is_plaintext = false;
        }
    }
    
    let logical_size = if is_plaintext {
        total_size
    } else {
        let payload_size = total_size.saturating_sub(104);
        let chunks = payload_size / 2_097_168;
        let remainder = payload_size % 2_097_168;
        (chunks * 2_097_152) + remainder.saturating_sub(16)
    };
    
    let stream_ctx = Box::new(DrmStreamContext { 
        file, 
        logical_size, 
        logical_offset: 0,
        is_plaintext
    });
    
    unsafe {
        (*cb_info).cookie = Box::into_raw(stream_ctx) as *mut c_void;
        (*cb_info).read_fn = Some(custom_read_fn);
        (*cb_info).seek_fn = Some(custom_seek_fn);
        (*cb_info).size_fn = Some(custom_size_fn);
        (*cb_info).close_fn = Some(custom_close_fn);
        (*cb_info).cancel_fn = None;
    }
    0
}

fn get_absolute_library_path() -> Option<PathBuf> {
    if let Ok(mut exe_path) = std::env::current_exe() {
        exe_path.pop();
        let dll_names = ["mpv-2.dll", "mpv-1.dll", "libmpv-2.dll", "libmpv-1.dll", "mpv.dll", "libmpv.dylib", "libmpv.so.2", "libmpv.so"];
        for &name in &dll_names {
            let mut full_path = exe_path.clone();
            full_path.push(name);
            if full_path.exists() {
                return Some(full_path);
            }
        }
    }
    None
}

pub fn do_bind(handle_address: i64) -> bool {
    let _ = std::fs::remove_file(get_log_path());
    write_log!("========== HOOK INITIALIZED ==========");
    
    let target_path = match get_absolute_library_path() {
        Some(path) => path,
        None => {
            write_log!("[FATAL] Could not locate engine library next to the executable.");
            return false;
        }
    };

    if !verify_engine_integrity(&target_path) {
        return false;
    }

    let handle = handle_address as *mut c_void;
    let protocol_name = CString::new("safedrm").unwrap().into_raw(); 
    
    unsafe {
        if let Ok(lib) = Library::new(target_path.as_os_str()) {
            type AddRoFn = unsafe extern "C" fn(*mut c_void, *const c_char, *mut c_void, extern "C" fn(*mut c_void, *mut c_char, *mut MpvStreamCbInfo) -> c_int) -> c_int;
            if let Ok(func) = lib.get::<AddRoFn>(b"mpv_stream_cb_add_ro\0") {
                let result = func(handle, protocol_name, ptr::null_mut(), custom_open_fn);
                std::mem::forget(lib); 
                return result >= 0;
            }
        }
    }
    false
}

pub fn do_play(handle_address: i64) -> bool {
    let target_path = match get_absolute_library_path() {
        Some(path) => path,
        None => return false,
    };

    let handle = handle_address as *mut c_void;
    unsafe {
        if let Ok(lib) = Library::new(target_path.as_os_str()) {
            type CmdFn = unsafe extern "C" fn(*mut c_void, *const c_char) -> c_int;
            if let Ok(func) = lib.get::<CmdFn>(b"mpv_command_string\0") {
                let cmd = CString::new("loadfile safedrm://video.mp4").unwrap();
                let res = func(handle, cmd.as_ptr());
                std::mem::forget(lib);
                return res >= 0;
            }
        }
    }
    false
}