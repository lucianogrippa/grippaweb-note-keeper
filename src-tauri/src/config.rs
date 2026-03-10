use std::fs;

use tauri::{Emitter, Manager};

use crate::db::DBManager;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Config {
    pub database_path: String,
    pub database_password: String,
}


impl Config {
    pub fn new() -> Self {

        // load env variables from .env file
        dotenvy::dotenv().ok();

        // get user data directory
        let user_data_dir = dirs::data_dir().unwrap_or_else(|| std::path::PathBuf::from("."));
        let default_database_path = user_data_dir.join("notes.db");

        println!("Default database path: {:?}", default_database_path);

        // load password from environment variable or use default
        let database_password = std::env::var("DATABASE_PASSWORD").unwrap_or_else(|_| "".to_string());
        let database_path = std::env::var("DATABASE_PATH").unwrap_or_else(|_| default_database_path.to_str().unwrap().to_string());

        Self {
            database_path,
            database_password,
        }
    }
}

pub async fn setup(_app: &tauri::App) {
    let _ = Config::new();
}