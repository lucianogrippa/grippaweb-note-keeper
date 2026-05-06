use aes_gcm::aead::Aead;
use aes_gcm::{Aes256Gcm, Key, KeyInit, Nonce};
use argon2::{Argon2, Params};
use base64::{engine::general_purpose, Engine as _};
use rand::{thread_rng, RngCore};
use std::error::Error;

const LEGACY_SALT_LEN: usize = 16;
const NONCE_LEN: usize = 12;
const KEY_LEN: usize = 32;
const FAST_FORMAT_PREFIX: &str = "v2:";

fn decode_raw_key(password: &str) -> Result<[u8; KEY_LEN], Box<dyn Error>> {
    let decoded = hex::decode(password)?;
    if decoded.len() != KEY_LEN {
        return Err("La chiave deve essere lunga 32 byte".into());
    }

    let mut key = [0u8; KEY_LEN];
    key.copy_from_slice(&decoded);
    Ok(key)
}

fn derive_legacy_key(password: &str, salt: &[u8]) -> Result<[u8; KEY_LEN], Box<dyn Error>> {
    let params = Params::new(64 * 1024, 3, 1, None).unwrap(); // memory_kib, iter, lanes, output_len(None->default)
    let argon2 = Argon2::new(argon2::Algorithm::Argon2id, argon2::Version::V0x13, params);

    let mut out = [0u8; KEY_LEN];
    argon2.hash_password_into(password.as_bytes(), salt, &mut out).unwrap();
    Ok(out)
}

fn encrypt_with_raw_key(key_bytes: &[u8; KEY_LEN], plaintext: &[u8]) -> Result<String, Box<dyn Error>> {
    let key = Key::<Aes256Gcm>::from_slice(key_bytes);
    let cipher = Aes256Gcm::new(key);

    let mut nonce_bytes = [0u8; NONCE_LEN];
    thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher.encrypt(nonce, plaintext.as_ref()).unwrap();

    let mut out = Vec::with_capacity(NONCE_LEN + ciphertext.len());
    out.extend_from_slice(&nonce_bytes);
    out.extend_from_slice(&ciphertext);

    Ok(format!("{}{}", FAST_FORMAT_PREFIX, general_purpose::STANDARD.encode(&out)))
}

fn decrypt_with_raw_key(key_bytes: &[u8; KEY_LEN], input_b64: &str) -> Result<Vec<u8>, Box<dyn Error>> {
    let raw = general_purpose::STANDARD.decode(input_b64)?;
    if raw.len() < NONCE_LEN + 1 {
        return Err("Input troppo corto".into());
    }

    let key = Key::<Aes256Gcm>::from_slice(key_bytes);
    let cipher = Aes256Gcm::new(key);

    let nonce_bytes = &raw[..NONCE_LEN];
    let ciphertext = &raw[NONCE_LEN..];
    let nonce = Nonce::from_slice(nonce_bytes);

    let plaintext = cipher
        .decrypt(nonce, ciphertext.as_ref())
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;
    Ok(plaintext)
}

fn encrypt_legacy(password: &str, plaintext: &[u8]) -> Result<String, Box<dyn Error>> {
    let mut salt = [0u8; LEGACY_SALT_LEN];
    thread_rng().fill_bytes(&mut salt);

    let key_bytes = derive_legacy_key(password, &salt)?;
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);

    let mut nonce_bytes = [0u8; NONCE_LEN];
    thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher.encrypt(nonce, plaintext.as_ref()).unwrap();

    let mut out = Vec::with_capacity(LEGACY_SALT_LEN + NONCE_LEN + ciphertext.len());
    out.extend_from_slice(&salt);
    out.extend_from_slice(&nonce_bytes);
    out.extend_from_slice(&ciphertext);

    Ok(general_purpose::STANDARD.encode(&out))
}

fn decrypt_legacy(password: &str, input_b64: &str) -> Result<Vec<u8>, Box<dyn Error>> {
    let raw = general_purpose::STANDARD.decode(input_b64)?;
    if raw.len() < LEGACY_SALT_LEN + NONCE_LEN + 1 {
        return Err("Input troppo corto".into());
    }

    let salt = &raw[..LEGACY_SALT_LEN];
    let nonce_bytes = &raw[LEGACY_SALT_LEN..LEGACY_SALT_LEN + NONCE_LEN];
    let ciphertext = &raw[LEGACY_SALT_LEN + NONCE_LEN..];

    let key_bytes = derive_legacy_key(password, salt)?;
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);

    let nonce = Nonce::from_slice(nonce_bytes);

    let plaintext = cipher
        .decrypt(nonce, ciphertext.as_ref())
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;
    Ok(plaintext)
}

/// Cifra il plaintext con la password. Quando la password è la chiave nota in formato esadecimale,
/// usa un formato veloce basato direttamente sulla chiave; altrimenti mantiene il formato legacy.
pub fn encrypt(password: &str, plaintext: &[u8]) -> Result<String, Box<dyn Error>> {
    match decode_raw_key(password) {
        Ok(key_bytes) => encrypt_with_raw_key(&key_bytes, plaintext),
        Err(_) => encrypt_legacy(password, plaintext),
    }
}

/// Decifra l'input cifrato. Supporta sia il formato veloce `v2:` sia il formato legacy.
pub fn decrypt(password: &str, input_b64: &str) -> Result<Vec<u8>, Box<dyn Error>> {
    if let Some(encoded) = input_b64.strip_prefix(FAST_FORMAT_PREFIX) {
        let key_bytes = decode_raw_key(password)?;
        return decrypt_with_raw_key(&key_bytes, encoded);
    }

    decrypt_legacy(password, input_b64)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn roundtrip_fast_path() {
        let password = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        let message = b"Ciao mondo, questo e' un test!";
        let enc = encrypt(password, message).expect("encrypt failed");
        assert!(enc.starts_with(FAST_FORMAT_PREFIX));
        let dec = decrypt(password, &enc).expect("decrypt failed");
        assert_eq!(dec, message);
    }

    #[test]
    fn legacy_roundtrip_still_works() {
        let password = "mia-chiave-segreta";
        let message = b"Segreto";
        let enc = encrypt(password, message).expect("encrypt failed");
        let dec = decrypt(password, &enc).expect("decrypt failed");
        assert_eq!(dec, message);
    }

    #[test]
    fn wrong_password_fails() {
        let password = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        let message = b"Segreto";
        let enc = encrypt(password, message).expect("encrypt failed");
        let res = decrypt("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", &enc);
        assert!(res.is_err());
    }
}