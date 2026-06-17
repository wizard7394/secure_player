use std::sync::Mutex;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;

lazy_static! {
    pub static ref DECRYPTION_STATE: Mutex<DecryptionKeys> = Mutex::new(DecryptionKeys {
        key: vec![],
        iv: vec![],
    });
}

pub struct DecryptionKeys {
    pub key: Vec<u8>,
    pub iv: Vec<u8>,
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