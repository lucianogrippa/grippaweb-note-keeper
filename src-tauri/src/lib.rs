mod commands;
mod db;
mod entities;
mod management;

use crate::commands::auth;
use crate::commands::profile;
use crate::commands::categories;
use sqlx::SqlitePool;
use std::sync::Arc;
use tauri::Manager;
use tokio::sync::RwLock;

// Application state to hold the database connection pool and encryption key

pub struct AppState {
    pub pool: Arc<RwLock<Option<SqlitePool>>>,
    pub encryption_key: Arc<RwLock<Option<[u8; 32]>>>,
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .invoke_handler(tauri::generate_handler![
            auth::is_db_exist,
            auth::register,
            auth::login,
            auth::logout,
            profile::get_user_profile,
            profile::reset_app,
            categories::get_categories_by_user,
            categories::add_category,
        ])
        .setup(|app| {
            // manage application state for database connection pool and encryption key
            let state = AppState {
                pool: Arc::new(RwLock::new(None)), // Initially, no database connection pool
                encryption_key: Arc::new(RwLock::new(None)), // Initially, no encryption key
            };
            app.manage(state);
            Ok(())
        })
        //.invoke_handler(tauri::generate_handler![greet])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
