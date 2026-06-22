use std::sync::Mutex;
use std::process::Command;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

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

pub fn get_system_hardware_id() -> String {
    #[cfg(target_os = "windows")]
    {
        let mut wmic_cmd = Command::new("wmic");
        wmic_cmd.creation_flags(0x08000000);
        
        if let Ok(output) = wmic_cmd.args(["csproduct", "get", "uuid"]).output() {
            let result = String::from_utf8_lossy(&output.stdout);
            for line in result.lines() {
                let trimmed = line.trim();
                if !trimmed.is_empty() && trimmed.to_lowercase() != "uuid" {
                    return trimmed.to_string();
                }
            }
        }
        
        let mut ps_cmd = Command::new("powershell");
        ps_cmd.creation_flags(0x08000000);
        
        if let Ok(output) = ps_cmd
            .args(["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", "(Get-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Cryptography').MachineGuid"])
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
        if let Ok(output) = Command::new("ioreg").args(["-rd1", "-c", "IOPlatformExpertDevice"]).output() {
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
        return "UNKNOWN_DESKTOP_HWID".to_string();
    }
}

pub fn get_system_specs() -> String {
    #[cfg(target_os = "windows")]
    {
        let ps_script = r#"
            $cpu = (Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name) -join ', '
            $gpu = (Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty Name) -join ', '
            $mb_m = (Get-WmiObject Win32_BaseBoard | Select-Object -ExpandProperty Manufacturer) -join ''
            $mb_p = (Get-WmiObject Win32_BaseBoard | Select-Object -ExpandProperty Product) -join ''
            $os = (Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption) -join ''
            
            $capture = (Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match 'Capture|Elgato|AVerMedia|Blackmagic|Cam Link|Live Gamer' } | Select-Object -ExpandProperty Name) -join ', '
            if (-not $capture) { $capture = 'Clean (No Capture Cards)' }
            
            Write-Output "OS: $os`nCPU: $cpu`nGPU: $gpu`nBoard: $mb_m $mb_p`nCapture HW: $capture"
        "#;

        let mut ps_cmd = Command::new("powershell");
        ps_cmd.creation_flags(0x08000000);

        if let Ok(output) = ps_cmd
            .args(["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", ps_script])
            .output() 
        {
            let result = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if !result.is_empty() {
                return result;
            }
        }
        return "Failed to bypass OS restriction".to_string();
    }

    #[cfg(target_os = "macos")]
    {
        let script = r#"
            os=$(sw_vers -productVersion)
            cpu=$(sysctl -n machdep.cpu.brand_string)
            model=$(sysctl -n hw.model)
            gpu=$(system_profiler SPDisplaysDataType | grep "Chipset Model" | awk -F': ' '{print $2}' | paste -sd ", ")
            capture=$(system_profiler SPCameraDataType SPUSBDataType | grep -iE 'capture|elgato|cam link|blackmagic' | awk -F': ' '{print $1}' | paste -sd ", ")
            if [ -z "$capture" ]; then capture="Clean"; fi
            echo "OS: macOS $os\nModel: $model\nCPU: $cpu\nGPU: $gpu\nCapture HW: $capture"
        "#;

        if let Ok(output) = Command::new("sh").args(["-c", script]).output() {
            return String::from_utf8_lossy(&output.stdout).trim().to_string();
        }
        return "Failed to read macOS specs".to_string();
    }

    #[cfg(target_os = "linux")]
    {
        let script = r#"
            os=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)
            cpu=$(grep 'model name' /proc/cpuinfo | head -n 1 | cut -d ':' -f 2 | xargs)
            gpu=$(lspci | grep -i vga | cut -d ':' -f 3 | xargs)
            echo "OS: $os\nCPU: $cpu\nGPU: $gpu"
        "#;

        if let Ok(output) = Command::new("sh").args(["-c", script]).output() {
            return String::from_utf8_lossy(&output.stdout).trim().to_string();
        }
        return "Failed to read Linux specs".to_string();
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        return "OS: Unsupported Platform".to_string();
    }
}