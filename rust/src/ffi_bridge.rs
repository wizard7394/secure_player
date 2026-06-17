use std::os::raw::{c_char, c_void, c_int};
use std::ffi::{CStr, CString};
use std::io::{Read, Seek, SeekFrom};
use std::fs::File;
use std::ptr;
use libloading::Library;
use aes::cipher::{KeyIvInit, StreamCipher, StreamCipherSeek};

type Aes128Ctr = ctr::Ctr128BE<aes::Aes128>;
type Aes256Ctr = ctr::Ctr128BE<aes::Aes256>;

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
    pub file_size: u64,
    pub current_offset: u64,
}

pub extern "C" fn custom_read_fn(cookie: *mut c_void, buf: *mut c_char, size: u64) -> i64 {
    if cookie.is_null() { return -1; }
    let ctx = unsafe { &mut *(cookie as *mut DrmStreamContext) };
    
    let buffer_size = std::cmp::min(size as usize, 1024 * 1024 * 5);
    let mut temp_buffer = vec![0u8; buffer_size];
    
    match ctx.file.read(&mut temp_buffer) {
        Ok(bytes_read) => {
            if bytes_read == 0 { return 0; }
            
            let state = crate::api::simple::DECRYPTION_STATE.lock().unwrap();
            let key = &state.key;
            let iv = &state.iv;
            
            if key.len() == 16 || key.len() == 32 {
                if key.len() == 16 {
                    if let Ok(mut cipher) = Aes128Ctr::new_from_slices(key, iv) {
                        cipher.seek(ctx.current_offset);
                        cipher.apply_keystream(&mut temp_buffer[..bytes_read]);
                    }
                } else if key.len() == 32 {
                    if let Ok(mut cipher) = Aes256Ctr::new_from_slices(key, iv) {
                        cipher.seek(ctx.current_offset);
                        cipher.apply_keystream(&mut temp_buffer[..bytes_read]);
                    }
                }
            }
            
            unsafe { ptr::copy_nonoverlapping(temp_buffer.as_ptr(), buf as *mut u8, bytes_read); }
            ctx.current_offset += bytes_read as u64;
            bytes_read as i64
        }
        Err(_) => -1,
    }
}

pub extern "C" fn custom_seek_fn(cookie: *mut c_void, offset: i64) -> i64 {
    if cookie.is_null() { return -1; }
    let ctx = unsafe { &mut *(cookie as *mut DrmStreamContext) };
    
    match ctx.file.seek(SeekFrom::Start(offset as u64)) {
        Ok(new_pos) => {
            ctx.current_offset = new_pos;
            new_pos as i64
        },
        Err(_) => -1,
    }
}

pub extern "C" fn custom_size_fn(cookie: *mut c_void) -> i64 {
    if cookie.is_null() { return -1; }
    let ctx = unsafe { &mut *(cookie as *mut DrmStreamContext) };
    ctx.file_size as i64
}

pub extern "C" fn custom_close_fn(cookie: *mut c_void) {
    if !cookie.is_null() { 
        unsafe { let _ = Box::from_raw(cookie as *mut DrmStreamContext); } 
    }
}

pub extern "C" fn custom_open_fn(
    _cookie: *mut c_void,
    uri: *mut c_char,
    cb_info: *mut MpvStreamCbInfo,
) -> c_int {
    if uri.is_null() || cb_info.is_null() { return -1; }
    
    let uri_str = unsafe { CStr::from_ptr(uri).to_string_lossy().into_owned() };
    let file_path = uri_str.replace("safedrm://", "");
    
    let file = match File::open(&file_path) {
        Ok(f) => f,
        Err(_) => return -1,
    };
    
    let file_size = file.metadata().unwrap().len();
    let stream_ctx = Box::new(DrmStreamContext { 
        file, 
        file_size,
        current_offset: 0,
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

pub fn do_bind(handle_address: i64) -> bool {
    let handle = handle_address as *mut c_void;
    let protocol_name = CString::new("safedrm").unwrap();
    
    unsafe {
        println!("RUST_ENGINE: Initializing memory hooks...");
        
        let dll_names = [
            "mpv-2.dll", 
            "mpv-1.dll", 
            "libmpv-2.dll", 
            "libmpv-1.dll", 
            "mpv.dll", 
            "libmpv.dylib", 
            "libmpv.so.2", 
            "libmpv.so"
        ];
        
        let mut loaded_lib = None;

        for &name in &dll_names {
            match Library::new(name) {
                Ok(lib) => {
                    println!("RUST_ENGINE: Successfully hooked into running module -> {}", name);
                    loaded_lib = Some(lib);
                    break;
                }
                Err(_) => {} 
            }
        }

        if loaded_lib.is_none() {
            if let Ok(mut exe_path) = std::env::current_exe() {
                exe_path.pop(); 
                for &name in &dll_names {
                    let mut full_path = exe_path.clone();
                    full_path.push(name);
                    match Library::new(full_path.as_os_str()) {
                        Ok(lib) => {
                            println!("RUST_ENGINE: Successfully loaded from absolute path -> {:?}", full_path);
                            loaded_lib = Some(lib);
                            break;
                        }
                        Err(_) => {}
                    }
                }
            }
        }
            
        match loaded_lib {
            Some(lib) => {
                println!("RUST_ENGINE: Binary loaded. Mapping symbols...");
                type AddRoFn = unsafe extern "C" fn(
                    *mut c_void, *const c_char, *mut c_void, 
                    extern "C" fn(*mut c_void, *mut c_char, *mut MpvStreamCbInfo) -> c_int
                ) -> c_int;
                
                match lib.get::<AddRoFn>(b"mpv_stream_cb_add_ro\0") {
                    Ok(func) => {
                        let result = func(handle, protocol_name.as_ptr(), ptr::null_mut(), custom_open_fn);
                        println!("RUST_ENGINE: Handshake completed with code: {}", result);
                        std::mem::forget(lib); 
                        return result >= 0;
                    }
                    Err(err) => println!("RUST_ENGINE: Symbol 'mpv_stream_cb_add_ro' not found -> {:?}", err),
                }
            }
            None => println!("RUST_ENGINE: FATAL -> Could not find any mpv binary on this system!"),
        }
    }
    false
}