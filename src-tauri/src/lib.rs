mod commands;
mod db;
mod entities;
mod management;

use crate::commands::auth;
use crate::commands::profile;
use crate::commands::categories;
use crate::commands::groups;
use crate::commands::notes;
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
            categories::update_category,
            categories::find_category_by_id,
            categories::search_categories,
            categories::delete_category_by_id,
            groups::get_groups_by_category,
            groups::find_group_by_id,
            groups::add_group_in_category,
            groups::edit_group,
            groups::delete_group,
            notes::get_notes_by_group,
            notes::find_note_by_id,
            notes::add_note_in_group,
            notes::edit_note,
            notes::delete_note,
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
