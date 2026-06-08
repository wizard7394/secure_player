use axum::{
    http::{header, HeaderMap, StatusCode, Response},
    routing::get,
    Router,
    body::Body,
};
use std::sync::{Arc, OnceLock};
use tokio::net::TcpListener;
use tokio::sync::Mutex;
use tokio::fs::File;
use tokio::io::{AsyncReadExt, AsyncSeekExt};
use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Key, Nonce,
};
use tokio::sync::mpsc;
use tokio_stream::wrappers::ReceiverStream;
use bytes::Bytes;

const CHUNK_SIZE: usize = 32 * 1024 * 1024;
const ENCRYPTED_CHUNK_SIZE: usize = CHUNK_SIZE + 16;

pub struct PlayerState {
    pub file_path: String,
    pub aes_key: Vec<u8>,
    pub aes_iv: Vec<u8>,
}

static GLOBAL_STATE: OnceLock<Arc<Mutex<PlayerState>>> = OnceLock::new();

fn get_state() -> Arc<Mutex<PlayerState>> {
    GLOBAL_STATE.get_or_init(|| {
        Arc::new(Mutex::new(PlayerState {
            file_path: String::new(),
            aes_key: Vec::new(),
            aes_iv: Vec::new(),
        }))
    }).clone()
}

pub async fn start_proxy_server(
    port: u16,
    file_path: String,
    aes_key: Vec<u8>,
    aes_iv: Vec<u8>,
) -> String {
    let state = get_state();
    {
        let mut lock = state.lock().await;
        lock.file_path = file_path;
        lock.aes_key = aes_key;
        lock.aes_iv = aes_iv;
    }

    let addr = format!("127.0.0.1:{}", port);
    
    match TcpListener::bind(&addr).await {
        Ok(listener) => {
            let app = Router::new().route("/stream", get(stream_handler));
            tokio::spawn(async move {
                let _ = axum::serve(listener, app).await;
            });
        }
        Err(e) if e.kind() == std::io::ErrorKind::AddrInUse => {
            println!("Proxy server is already running on {}. State updated.", addr);
        }
        Err(e) => {
            eprintln!("Failed to bind port: {}", e);
        }
    }

    format!("http://{}/stream", addr)
}

async fn stream_handler(headers: HeaderMap) -> Response<Body> {
    let state = get_state();
    let state_lock = state.lock().await;
    let file_path = state_lock.file_path.clone();
    let aes_key = state_lock.aes_key.clone();
    let aes_iv = state_lock.aes_iv.clone();
    drop(state_lock);

    let file_meta = match tokio::fs::metadata(&file_path).await {
        Ok(m) => m,
        Err(_) => return Response::builder().status(StatusCode::NOT_FOUND).body(Body::empty()).unwrap(),
    };
    
    let encrypted_size = file_meta.len();
    let num_chunks = (encrypted_size + ENCRYPTED_CHUNK_SIZE as u64 - 1) / ENCRYPTED_CHUNK_SIZE as u64;
    let decrypted_size = encrypted_size - (num_chunks * 16);

    let mut start_byte = 0u64;
    let mut end_byte = decrypted_size - 1;
    let mut is_partial = false;

    if let Some(range_val) = headers.get(header::RANGE) {
        if let Ok(range_str) = range_val.to_str() {
            if range_str.starts_with("bytes=") {
                let parts: Vec<&str> = range_str[6..].split('-').collect();
                if parts.len() == 2 {
                    if let Ok(s) = parts[0].parse::<u64>() { start_byte = s; }
                    if let Ok(e) = parts[1].parse::<u64>() { end_byte = e; } 
                    else if parts[1] == "" { end_byte = decrypted_size - 1; }
                }
                is_partial = true;
            }
        }
    }

    if start_byte >= decrypted_size {
        return Response::builder().status(StatusCode::RANGE_NOT_SATISFIABLE).body(Body::empty()).unwrap();
    }

    let content_length = end_byte - start_byte + 1;

    let mut response_builder = Response::builder()
        .header(header::CONTENT_TYPE, "video/mp4")
        .header(header::ACCEPT_RANGES, "bytes")
        .header(header::CONTENT_LENGTH, content_length.to_string());

    if is_partial {
        response_builder = response_builder
            .status(StatusCode::PARTIAL_CONTENT)
            .header(header::CONTENT_RANGE, format!("bytes {}-{}/{}", start_byte, end_byte, decrypted_size));
    }

    let (tx, rx) = mpsc::channel::<Result<Bytes, std::io::Error>>(10);

    tokio::spawn(async move {
        let mut file = match File::open(&file_path).await {
            Ok(f) => f,
            Err(_) => return,
        };

        let start_chunk = (start_byte / CHUNK_SIZE as u64) as u32;
        let start_offset_in_chunk = (start_byte % CHUNK_SIZE as u64) as usize;

        let seek_pos = (start_chunk as u64) * (ENCRYPTED_CHUNK_SIZE as u64);
        if file.seek(std::io::SeekFrom::Start(seek_pos)).await.is_err() { return; }

        let mut buffer = vec![0u8; ENCRYPTED_CHUNK_SIZE];
        let mut chunk_index = start_chunk;
        let mut bytes_sent = 0u64;

        let key = Key::<Aes256Gcm>::from_slice(&aes_key);
        let cipher = Aes256Gcm::new(key);

        loop {
            if bytes_sent >= content_length { break; }

            let mut current_read = 0;
            while current_read < ENCRYPTED_CHUNK_SIZE {
                match file.read(&mut buffer[current_read..ENCRYPTED_CHUNK_SIZE]).await {
                    Ok(0) => break,
                    Ok(n) => current_read += n,
                    Err(_) => break,
                }
            }

            if current_read == 0 { break; }

            let data_to_decrypt = &buffer[..current_read];
            let mut chunk_iv = aes_iv.clone();
            let pos_bytes = chunk_index.to_le_bytes();

            let len = chunk_iv.len();
            for i in 0..4 { chunk_iv[len - 4 + i] ^= pos_bytes[i]; }

            let nonce = Nonce::from_slice(&chunk_iv);

            match cipher.decrypt(nonce, data_to_decrypt) {
                Ok(plain_text) => {
                    let mut start_idx = 0;
                    if chunk_index == start_chunk { start_idx = start_offset_in_chunk; }

                    if start_idx < plain_text.len() {
                        let mut slice = &plain_text[start_idx..];
                        let remaining = content_length - bytes_sent;
                        if (slice.len() as u64) > remaining {
                            slice = &slice[..(remaining as usize)];
                        }

                        if tx.send(Ok(Bytes::from(slice.to_vec()))).await.is_err() { break; }
                        bytes_sent += slice.len() as u64;
                    }
                }
                Err(_) => break,
            }
            chunk_index += 1;
        }
    });

    let stream = ReceiverStream::new(rx);
    let body = Body::from_stream(stream);

    response_builder.body(body).unwrap()
}