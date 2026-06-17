use std::sync::Mutex;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;

lazy_static! {
    pub static ref DECRYPTION_STATE: Mutex<DecryptionKeys> = Mutex::new(DecryptionKeys {
        key: vec![],
        iv: vec![],
        file_path: String::new(),
    });
}

pub struct DecryptionKeys {
    pub key: Vec<u8>,
    pub iv: Vec<u8>,
    pub file_path: String,
}

#[frb(sync)]
pub fn set_decryption_keys(key: Vec<u8>, iv: Vec<u8>, file_path: String) {
    let mut state = DECRYPTION_STATE.lock().unwrap();
    state.key = key;
    state.iv = iv;
    state.file_path = file_path;
}

#[frb(sync)]
pub fn clear_decryption_keys() {
    let mut state = DECRYPTION_STATE.lock().unwrap();
    
    // Security: Overwrite keys with zeros before clearing to prevent memory scraping
    for byte in state.key.iter_mut() { *byte = 0; }
    for byte in state.iv.iter_mut() { *byte = 0; }
    
    state.key.clear();
    state.iv.clear();
    state.file_path.clear();
}

#[frb(sync)]
pub fn bind_secure_protocol(handle_address: i64) -> bool {
    crate::ffi_bridge::do_bind(handle_address)
}

#[frb(sync)]
pub fn play_secure_stream(handle_address: i64) -> bool {
    crate::ffi_bridge::do_play(handle_address)
}