use aes_gcm::{Aes256Gcm, Key, KeyInit, Nonce}; // Or `Aes128Gcm` se usi una chiave da 16 byte
use aes_gcm::aead::{Aead};
use argon2::{Argon2, Params};
use argon2::password_hash::{ rand_core::OsRng};
use base64::{engine::general_purpose, Engine as _};
use rand::RngCore;
use std::error::Error;

/// Parametri fissi
const SALT_LEN: usize = 16;
const NONCE_LEN: usize = 12; // AES-GCM standard nonce
const KEY_LEN: usize = 32; // 256-bit key for Aes256Gcm

/// Deriva una chiave KEY_LEN bytes da una password e salt usando Argon2id.
/// Usa parametri consigliati; puoi regolarli per bilanciare sicurezza/prestazioni.
fn derive_key(password: &str, salt: &[u8]) -> Result<[u8; KEY_LEN], Box<dyn Error>> {
    // Configurazione Argon2: memory = 64 MiB, iterations = 3, parallelism = 1
    let params = Params::new(64 * 1024, 3, 1, None).unwrap(); // memory_kib, iter, lanes, output_len(None->default)
    let argon2 = Argon2::new(argon2::Algorithm::Argon2id, argon2::Version::V0x13, params);

    // Use password_hash API to produce raw key bytes via PBKDF-like interface:
    // We will use SaltString only to format; then use hash_raw via Argon2::hash_password_into
    let mut out = [0u8; KEY_LEN];
    argon2.hash_password_into(password.as_bytes(), salt, &mut out).unwrap();
    Ok(out)
}

/// Cifra il plaintext con la password. Restituisce Base64(salt||nonce||ciphertext).
pub fn encrypt(password: &str, plaintext: &[u8]) -> Result<String, Box<dyn Error>> {
    // genera salt casuale
    let mut salt = [0u8; SALT_LEN];
    OsRng.fill_bytes(&mut salt);

    // ricava la chiave
    let key_bytes = derive_key(password, &salt)?;
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);

    // genera nonce casuale
    let mut nonce_bytes = [0u8; NONCE_LEN];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    // cifratura (Aead gestisce autenticazione e tag)
    let ciphertext = cipher.encrypt(nonce, plaintext.as_ref()).unwrap();

    // concatena salt || nonce || ciphertext
    let mut out = Vec::with_capacity(SALT_LEN + NONCE_LEN + ciphertext.len());
    out.extend_from_slice(&salt);
    out.extend_from_slice(&nonce_bytes);
    out.extend_from_slice(&ciphertext);

    // Base64 encode per memorizzazione/trasferimento
    Ok(general_purpose::STANDARD.encode(&out))
}

/// Decifra l'input Base64(salt||nonce||ciphertext) con la password.
/// Restituisce il plaintext o errore se autenticazione fallisce.
pub fn decrypt(password: &str, input_b64: &str) -> Result<Vec<u8>, Box<dyn Error>> {
    let raw = general_purpose::STANDARD.decode(input_b64)?;
    if raw.len() < SALT_LEN + NONCE_LEN + 1 {
        return Err("Input troppo corto".into());
    }

    let salt = &raw[..SALT_LEN];
    let nonce_bytes = &raw[SALT_LEN..SALT_LEN + NONCE_LEN];
    let ciphertext = &raw[SALT_LEN + NONCE_LEN..];

    let key_bytes = derive_key(password, salt)?;
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);

    let nonce = Nonce::from_slice(nonce_bytes);

    let plaintext = cipher.decrypt(nonce, ciphertext.as_ref()).unwrap();
    Ok(plaintext)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn roundtrip() {
        let password = "mia-chiave-segreta";
        let message = b"Ciao mondo, questo e' un test!";
        let enc = encrypt(password, message).expect("encrypt failed");
        let dec = decrypt(password, &enc).expect("decrypt failed");
        assert_eq!(dec, message);
    }

    #[test]
    fn wrong_password_fails() {
        let password = "mia-chiave-segreta";
        let message = b"Segreto";
        let enc = encrypt(password, message).expect("encrypt failed");
        let res = decrypt("altra-password", &enc);
        assert!(res.is_err());
    }
}