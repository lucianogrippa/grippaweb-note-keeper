mod db_manager;
mod credential_service;
mod frontend_interface;
mod config;
use std::sync::Arc;
use tauri::Manager;
use tokio::sync::RwLock;
use sqlx::SqlitePool;

// Application state to hold the database connection pool and encryption key

pub struct AppState {
    pub pool: Arc<RwLock<Option<SqlitePool>>>,
    pub encryption_key: Arc<RwLock<Option<[u8; 32]>>>,
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    
    
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            frontend_interface::is_db_exist,
            frontend_interface::register,
        ])
        .setup(|app| {
            config::setup(app);

            // manage application state for database connection pool and encryption key
            tauri::async_runtime::block_on(async move {
                let state = AppState {
                    pool: Arc::new(RwLock::new(None)), // Initially, no database connection pool
                    encryption_key: Arc::new(RwLock::new(None)), // Initially, no encryption key
                };
                app.manage(state);
            });
            Ok(())
        })
        //.invoke_handler(tauri::generate_handler![greet])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
