pub mod repo_users;
pub mod repo_categories;
pub mod repo_groups;
pub mod repo_notes;

use crate::management::KeyManager;

use anyhow::{Context, Result};

use sqlx::sqlite::{SqliteConnectOptions, SqlitePool, SqlitePoolOptions};
use std::{fs, path::PathBuf, str::FromStr};
use tauri::{AppHandle, Manager as _};

pub struct DBManager;

impl DBManager {
    const MAX_CONNECTIONS: u32 = 1;
    const DB_NAME: &'static str = "18a72cbf45fd49906314f8285e82faf8.db";
}

/**
 * The DBManager struct provides methods for managing the application's database, including checking for the existence of the database file, creating and connecting to the database, running migrations, and saving user profile information.
 * It uses SQLx for database interactions and handles encryption using a master password.
 * The DBManager is designed to be used in conjunction with the frontend interface to facilitate user registration and login processes.
 * Key functionalities include:
 * - Checking if the database file exists in the application data directory.
 * - Creating the database file and setting up the database schema using migrations.
 * - Connecting to the database with encryption using a master password.
 * - Saving user profile information (full name and hashed note password) into the database after successful registration.
 * - Deleting the database directory if needed (e.g., during re-registration).
 */
impl DBManager {
    /**
     * Checks if the database file exists in the application data directory.
     * This function is used to determine if the application has been set up with a master password and database.
     * Returns a boolean indicating the existence of the database file.
     */
    pub async fn is_db_exist(app: &AppHandle) -> Result<bool> {
        let db_path = Self::get_db_path(app).await?;
        Ok(db_path.exists())
    }

    /**
     * Verifies the database connection by executing a simple query to ensure that the connection is valid and the database is accessible.
     * This is used to confirm that the provided master password is correct for encrypted databases and that the database file is not corrupted.
     * Returns an error if the connection cannot be established or the query fails, which can indicate issues with the database file or incorrect encryption key.
     */
    async fn verify_database_connection(pool: &SqlitePool) -> Result<()> {
        sqlx::query("SELECT count(*) FROM sqlite_master")
            .fetch_one(pool)
            .await
            .context("Failed to verify database connection")?;

        Ok(())
    }

    /**
     * Deletes the database directory and all its contents. This is typically used during the registration process if a database already exists, allowing for a fresh setup with a new master password and user profile.
     * It retrieves the application data directory path and removes the entire directory if it exists, effectively deleting the database file and any associated data. This function should be used with caution as it will permanently delete the database and all stored information.
     */
    pub async fn delete_db_directory(app: &AppHandle) -> Result<(), anyhow::Error> {
        let db_dir = app
            .path()
            .app_data_dir()
            .context("Failed to retrieve application data directory")?;

        if db_dir.exists() {
            fs::remove_dir_all(&db_dir)
                .with_context(|| format!("Failed to delete database directory at {:?}", db_dir))?;
        }

        Ok(())
    }

    /**
     * Creates the database file in the application data directory. This function is called during the registration process to set up a new database for the user.
     * It ensures that the application data directory exists and then constructs the full path for the database
     */
    async fn create_db_file(app: &AppHandle) -> Result<PathBuf, anyhow::Error> {
        let db_dir = app
            .path()
            .app_data_dir()
            .context("Failed to retrieve application data directory to create database file")?;

        std::fs::create_dir_all(&db_dir).context("Failed to create directory for database")?;
        let db_path = db_dir.join(DBManager::DB_NAME);

        Ok(db_path)
    }

    /**
     * Retrieves the full path to the database file in the application data directory. This function is used to determine where the database file is located for both registration and login processes.
     * It constructs the path by joining the application data directory with the predefined database file name. This allows the application to consistently access the database file regardless of the operating system or user environment, as
     * the application data directory is a standard location for storing application-specific data across different platforms.
     */
    pub async fn get_db_path(app: &AppHandle) -> Result<PathBuf> {
        let db_dir = app
            .path()
            .app_local_data_dir()
            .context("Failed to retrieve application data directory")?;
        let db_path = db_dir.join(DBManager::DB_NAME);

        Ok(db_path)
    }

    /**
     * Connects to the database with encryption using the provided master password.
     * This function is used during both registration and login processes to establish a connection to the encrypted database.
     */
    pub async fn connect_to_database(
        app: &AppHandle,
        db_path: &PathBuf,
        master_password: &str,
    ) -> Result<SqlitePool> {
        let db_uri = db_path.to_str().context("Invalid database path")?;

        // hash the master password and use it as the encryption key for the database connection
        let hashed_password = KeyManager::get_encryption_key(app, master_password).await?;

        let hashed_password_hex = hex::encode(hashed_password);

        let options = SqliteConnectOptions::from_str(db_uri)
            .context("Failed to parse database path")?
            .pragma("key", format!("'{}'", hashed_password_hex))
            .create_if_missing(true);

        let pool = SqlitePoolOptions::new()
            .max_connections(DBManager::MAX_CONNECTIONS)
            .connect_with(options)
            .await
            .context("Failed to connect to database")?;

        Self::verify_database_connection(&pool)
            .await
            .context("Failed to verify password for encrypted database")?;

        Ok(pool)
    }

    /**
     * Sets up the database by connecting to it with the provided master password and running any necessary migrations to ensure the database schema is up to date.
     * This function is typically called during the registration process after the database file has been created, and it ensures that the database is properly initialized and ready for use.
     */
    pub async fn setup_database(
        app: &AppHandle,
        db_path: &PathBuf,
        master_password: &str,
    ) -> Result<SqlitePool> {
        let pool = Self::connect_to_database(app, db_path, master_password).await?;

        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .context("Failed to run database migrations")?;

        Ok(pool)
    }
}
