use std::fs;

use tauri::Emitter;

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

pub fn setup(app: &tauri::App) {
    let _config = Config::new();

    // first check if database exists and if not send event to frontend to permit choose master password and then create db

     match fs::exists(&_config.database_path).unwrap_or_else(|_| false) {
        true => {
            println!("Database already exists at path: {}", _config.database_path);
        },
        false => {
            println!("Database does not exist at path: {}", _config.database_path);
            // send event to frontend to permit choose master password and then create db
            app.emit_to(tauri::EventTarget::Any, "setup_master_password", "").ok();
        }
     }
}