use std::sync::Mutex;
use std::process::Command;
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

#[frb(sync)]
pub fn get_system_hardware_id() -> String {
    #[cfg(target_os = "windows")]
    {
        // 1. Try WMIC
        if let Ok(output) = std::process::Command::new("wmic").args(["csproduct", "get", "uuid"]).output() {
            let result = String::from_utf8_lossy(&output.stdout);
            for line in result.lines() {
                let trimmed = line.trim();
                if !trimmed.is_empty() && trimmed.to_lowercase() != "uuid" {
                    return trimmed.to_string();
                }
            }
        }
        
        // 2. Fallback to Powershell Registry if WMIC fails
        if let Ok(output) = std::process::Command::new("powershell")
            .args(["-Command", "(Get-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Cryptography').MachineGuid"])
            .output() 
        {
             let result = String::from_utf8_lossy(&output.stdout);
             let trimmed = result.trim();
             if !trimmed.is_empty() {
                 return trimmed.to_string();
             }
        }
        return "UNKNOWN_WIN_HWID".to_string();
    }

    #[cfg(target_os = "macos")]
    {
        if let Ok(output) = std::process::Command::new("ioreg").args(["-rd1", "-c", "IOPlatformExpertDevice"]).output() {
            let result = String::from_utf8_lossy(&output.stdout);
            for line in result.lines() {
                if line.contains("IOPlatformUUID") {
                    let parts: Vec<&str> = line.split('=').collect();
                    if parts.len() == 2 {
                        return parts[1].replace("\"", "").trim().to_string();
                    }
                }
            }
        }
        return "UNKNOWN_MAC_HWID".to_string();
    }

    #[cfg(target_os = "linux")]
    {
        if let Ok(id) = std::fs::read_to_string("/etc/machine-id") {
            return id.trim().to_string();
        }
        if let Ok(id) = std::fs::read_to_string("/var/lib/dbus/machine-id") {
            return id.trim().to_string();
        }
        return "UNKNOWN_LINUX_HWID".to_string();
    }
    
    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        return "UNKNOWN_MOBILE_HWID".to_string();
    }
}