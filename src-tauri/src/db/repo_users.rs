use crate::db::DBManager;

use anyhow::{Context, Result};

use crate::entities::profiles::UserProfile;
use sqlx::sqlite::SqlitePool;
use tauri::AppHandle;

/**
 * Registers a new user by creating a database and setting up the master password and note password.
 */
pub async fn register(
    app: &AppHandle,
    full_name: &str,
    password_hash_note: &str,
    master_password: &str, // is clear
) -> Result<SqlitePool, anyhow::Error> {
    if full_name.is_empty() {
        return Err(anyhow::anyhow!("Full name cannot be empty"));
    }

    if password_hash_note.is_empty() {
        return Err(anyhow::anyhow!("Password hash note cannot be empty"));
    }

    if master_password.is_empty() {
        return Err(anyhow::anyhow!("Master password cannot be empty"));
    }

    if DBManager::is_db_exist(app).await.unwrap_or(false) {
        DBManager::delete_db_directory(app)
            .await
            .context("Failed to delete existing database directory during registration")?;
    }

    let db_path = DBManager::create_db_file(app).await?;
    let pool = DBManager::setup_database(app, &db_path, master_password).await?;

    // if the database was creadted successfully , insert the profile information into the database
    save_user_profile(full_name, password_hash_note, &pool).await?;
    Ok(pool)
}

/**
 * Logs in a user by connecting to the database with the provided master password.
 * This function is called during the login process to establish a connection to the encrypted database and verify that the master password is correct.
 * It attempts to connect to the database using the master password, and if successful, it returns the database connection pool.
 * If the connection fails (e.g., due to an incorrect master password or a corrupted database file), it returns an error indicating the failure to connect to the database.
 * This function is essential for ensuring that only users with the correct master password can access the encrypted database and its
 */
pub async fn login(app: &AppHandle, master_password: &str) -> Result<SqlitePool, anyhow::Error> {
    let db_path = DBManager::get_db_path(app).await?;

    if !db_path.exists() {
        return Err(anyhow::anyhow!("Database file does not exist"));
    }

    let pool = DBManager::connect_to_database(app, &db_path, master_password).await?;

    Ok(pool)
}

/**
 * Saves the user's profile information (full name and password hash note) into the database after successful registration.
 * This function is called after the database has been created and set up during the registration process.
 */
pub async fn save_user_profile(
    full_name: &str,
    password_hash_note: &str,
    pool: &sqlx::Pool<sqlx::Sqlite>,
) -> Result<(), anyhow::Error> {
    if full_name.is_empty() {
        return Err(anyhow::anyhow!("Full name cannot be empty"));
    }

    if password_hash_note.is_empty() {
        return Err(anyhow::anyhow!("Password hash note cannot be empty"));
    }

    // Get any existing profile id (TEXT)
    let existing_profile_id: Option<String> =
        sqlx::query_scalar("SELECT id FROM user_profile LIMIT 1")
            .fetch_optional(pool)
            .await
            .context("Failed to query existing profile")?;

    if let Some(profile_id) = existing_profile_id {
        sqlx::query(
            "UPDATE user_profile SET full_name = ?, password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
        )
            .bind(full_name)
            .bind(password_hash_note)
            .bind(profile_id)
            .execute(pool)
            .await
            .context("Failed to update profile information in database")?;
    } else {
        // Let SQLite generate TEXT id using DEFAULT
        sqlx::query(
            "INSERT INTO user_profile (full_name, password_hash, created_at, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        )
            .bind(full_name)
            .bind(password_hash_note)
            .execute(pool)
            .await
            .context("Failed to insert profile information into database")?;
    }

    Ok(())
}

pub async fn find_user_profile(
    pool: &sqlx::Pool<sqlx::Sqlite>,
) -> Result<Option<UserProfile>, anyhow::Error> {
    let profile = sqlx::query_as::<_, UserProfile>("SELECT * FROM user_profile LIMIT 1")
        .fetch_optional(pool)
        .await
        .context("Failed to query user profile from database")?;

    Ok(profile)
}

pub(crate) async fn reset_app(app: &AppHandle) -> Result<(), anyhow::Error> {
    // delete entire database file to reset the app
    DBManager::delete_db_directory(app).await.context("Failed to delete database directory during app reset")?;
    Ok(())
}
