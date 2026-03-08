/**
 * This module defines the frontend interface for the Tauri application, 
 * providing commands that can be invoked from the frontend to interact with the backend logic. 
 * It includes functions to check if the database exists and to register a new user by creating a database and deriving an encryption key.
 */

use tauri::AppHandle;
use crate::db_manager::DBManager;
use crate::AppState;
use tauri::State;
use crate::credential_service::argon2_key_derivation::KeyManager;


/**
 * Checks if the database file exists in the application data directory.
 * This function is invoked from the frontend to determine if the application has been set up with a master password and database.
 * Returns a boolean indicating the existence of the database file.
 */
#[tauri::command]
pub async fn is_db_exist(app: AppHandle) -> Result<bool, String> {
    let db_exist = DBManager::is_db_exist(&app).await.unwrap_or(false);
    Ok(db_exist)
}

/**
 * Registers a new user by creating a database and setting up the master password and note password.
 * This function is invoked from the frontend when the user submits the registration form with their full name, note password, master password, and encryption preference.
 * It performs the following steps:
 * 1. Checks if the master password is empty and returns an error if it is.
 * 2. Deletes any existing database if it exists to start fresh.
 * 3. Derives an encryption key from the master password using the KeyManager.
 * 4. Hashes the note password using the derived encryption key.
 * 5. Creates a new database and saves the user's profile information (full name and hashed note password).
 * 6. If encryption is not enabled, stores the master password hash in the database for future verification.
 * 7. Updates the application state with the new database connection pool and encryption key for use in subsequent operations.
 */
#[tauri::command]
pub async fn register(
    app: AppHandle,
    state: State<'_, AppState>,
    full_name: String,
    note_password: String,
    master_password: String
) -> Result<(), String> {
    if master_password.is_empty() {
        return Err("Password cannot be empty".to_string());
    }

    if DBManager::is_db_exist(&app).await.unwrap_or(false) {
        DBManager::delete_db_directory(&app)
            .await
            .map_err(|e| format!("Could not register: {}", e))?;
    }

    let encryption_key_error_handler = KeyManager::get_encryption_key(&app, &master_password)
            .await
            .map_err(|e| format!("Invalid password {}", e))?;
        
    let key: [u8; KeyManager::LEN_ENCRYPTION_KEY] = encryption_key_error_handler;

    let note_password_hash = KeyManager::hash_note_password(&note_password, &key)
        .map_err(|e| format!("Failed to hash note password: {}", e))?;

    let note_password_hash_hex = hex::encode(note_password_hash);

    let pool = DBManager::register(
        &app,
        &full_name,
        &note_password_hash_hex,
        &master_password
    )
        .await
        .map_err(|e| e.to_string())?;

    let mut pool_lock = state.pool.write().await;
    *pool_lock = Some(pool);

    let mut key_lock = state.encryption_key.write().await;
    *key_lock = Some(key);

    Ok(())
}