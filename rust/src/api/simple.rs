use std::sync::Mutex;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;

lazy_static! {
    static ref DECRYPTION_STATE: Mutex<DecryptionKeys> = Mutex::new(DecryptionKeys {
        key: vec![],
        iv: vec![],
    });
}

struct DecryptionKeys {
    key: Vec<u8>,
    iv: Vec<u8>,
}

#[frb(sync)]
pub fn set_decryption_keys(key: Vec<u8>, iv: Vec<u8>) {
    let mut state = DECRYPTION_STATE.lock().unwrap();
    state.key = key;
    state.iv = iv;
}

#[frb(sync)]
pub fn bind_secure_protocol(handle_address: i64) -> bool {
    crate::ffi_bridge::do_bind(handle_address)
}

// این یک wrapper برای صدا زدن تابع در FFI است
pub extern "C" fn custom_open_fn_wrapper(_cookie: *mut std::ffi::c_void, _uri: *mut std::os::raw::c_char, _cb: *mut crate::ffi_bridge::MpvStreamCbInfo) -> std::os::raw::c_int {
    0 // فعلاً برای تست بیلد
}