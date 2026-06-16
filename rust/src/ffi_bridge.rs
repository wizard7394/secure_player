use std::os::raw::{c_char, c_void, c_int};
use std::ffi::{CStr, CString};
use std::ptr;
use libloading::Library;

// فرض بر این است که MpvStreamCbInfo همان ساختاری است که مدیاکیت می‌شناسد
#[repr(C)]
pub struct MpvStreamCbInfo {
    pub cookie: *mut c_void,
    pub read_fn: Option<extern "C" fn(*mut c_void, *mut c_char, u64) -> i64>,
    pub seek_fn: Option<extern "C" fn(*mut c_void, i64) -> i64>,
    pub size_fn: Option<extern "C" fn(*mut c_void) -> i64>,
    pub close_fn: Option<extern "C" fn(*mut c_void)>,
    pub cancel_fn: Option<extern "C" fn(*mut c_void)>,
}

pub fn do_bind(handle_address: i64) -> bool {
    let handle = handle_address as *mut c_void;
    let protocol_name = CString::new("safedrm").unwrap();
    
    unsafe {
        let lib = Library::new("mpv-2.dll")
            .or_else(|_| Library::new("libmpv.dylib"))
            .or_else(|_| Library::new("libmpv.so.2"));
            
        if let Ok(lib) = lib {
            type AddRoFn = unsafe extern "C" fn(
                *mut c_void, *const c_char, *mut c_void, 
                extern "C" fn(*mut c_void, *mut c_char, *mut MpvStreamCbInfo) -> c_int
            ) -> c_int;
            
            if let Ok(func) = lib.get::<AddRoFn>(b"mpv_stream_cb_add_ro\0") {
                // تابع custom_open_fn باید در همین فایل تعریف شود
                return func(handle, protocol_name.as_ptr(), ptr::null_mut(), super::api::simple::custom_open_fn_wrapper) >= 0;
            }
        }
    }
    false
}