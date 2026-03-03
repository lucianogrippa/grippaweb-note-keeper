mod db;
mod config;


static  mut CONN: Option<sqlx::SqliteConnection> = None;


#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    
    
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            config::setup(app);
            Ok(())
        })
        //.invoke_handler(tauri::generate_handler![greet])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
