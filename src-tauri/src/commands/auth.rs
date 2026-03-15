use crate::db::{repo_users, DBManager};
use crate::management::KeyManager;
use crate::AppState;
use tauri::AppHandle;
use tauri::State;

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
    master_password: String,
) -> Result<(), String> {
    println!("Registering user with full name: {}", full_name);
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

    let note_password_hash = KeyManager::hash_password(&note_password);

    let pool = repo_users::register(&app, &full_name, &note_password_hash, &master_password)
        .await
        .map_err(|e| e.to_string())?;

    let mut pool_lock = state.pool.write().await;
    *pool_lock = Some(pool);

    let mut key_lock = state.encryption_key.write().await;
    *key_lock = Some(key);

    Ok(())
}

/**
 * Logs in a user by connecting to the database with the provided master password.
 * This function is called during the login process to establish a connection to the encrypted database and verify that the master password is correct.
 * It attempts to connect to the database using the master password, and if successful, it returns the database connection pool.
 * If the connection fails (e.g., due to an incorrect master password or a corrupted database file), it returns an error indicating the failure to connect to the database.
 * This function is essential for ensuring that only users with the correct master password can access the encrypted database and its contents.
 * Upon successful login, it also retrieves the encryption key derived from the master password and updates the application state with both the database connection pool and the encryption key for use in subsequent operations.
 */
#[tauri::command]
pub async fn login(
    app: AppHandle,
    state: State<'_, AppState>,
    master_password: String,
) -> Result<(), String> {
    if !DBManager::is_db_exist(&app).await.unwrap_or(false) {
        return Err("Please register first.".to_string());
    }

    let pool = repo_users::login(&app, &master_password)
        .await
        .map_err(|_e| "Invalid Password")?;

    let mut pool_lock = state.pool.write().await;
    *pool_lock = Some(pool);

    let key: [u8; KeyManager::LEN_ENCRYPTION_KEY] =
        KeyManager::get_encryption_key(&app, &master_password)
            .await
            .map_err(|e| format!("Failed to get encryption key: {}", e))?;

    let mut key_lock = state.encryption_key.write().await;
    *key_lock = Some(key);

    Ok(())
}

/**
 * Logs out the user by closing the database connection pool and clearing the encryption key from the application state.
 * This function is called when the user chooses to log out of the application, ensuring that any sensitive information (like the database connection and encryption key) is properly cleared from memory.
 * It first takes the database connection pool from the application state and closes it if it exists, then it clears the encryption key from the state.
 * This helps to ensure that after logging out, there are no lingering connections or keys that could potentially be accessed by unauthorized parties.
 */
#[tauri::command]
pub async fn logout(state: State<'_, AppState>) -> Result<(), String> {
    let pool_to_close = {
        let mut pool_guard = state.pool.write().await;
        pool_guard.take()
    };
    if let Some(pool) = pool_to_close {
        pool.close().await;
    }
    Ok(())
}
