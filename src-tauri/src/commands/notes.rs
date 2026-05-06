use tauri::State;

use crate::{AppState, db::{repo_notes::{create_note, get_all_notes_by_group_id}, repo_users::find_user_profile}, entities::categories::Note};

#[tauri::command]
pub async fn get_notes_by_group(
    group_id: String,
    state: State<'_, AppState>,
) -> Result<Vec<Note>, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;

    get_all_notes_by_group_id(&group_id, pool)
        .await
        .map_err(|e| format!("Failed to get notes: {}", e))
}

#[tauri::command]
pub async fn find_note_by_id(
    note_id: String,
    decrypt_content: bool,
    state: State<'_, AppState>,
) -> Result<Note, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;
    
    // mesure the time taken to find the user profile
    let start_time = std::time::Instant::now();
    let user_profile = find_user_profile(pool)
    .await
    .map_err(|e| format!("Failed to find user profile: {}", e))?
    .ok_or("User profile not found")?;

    let duration = start_time.elapsed();
    println!("Time taken to find user profile: {:?}", duration);

    let encryption_key = user_profile.note_password_hash.as_bytes();

    crate::db::repo_notes::get_note_by_id(note_id.as_str(), decrypt_content, encryption_key, pool)
        .await
        .map_err(|e| format!("Failed to find note: {}", e))
}

#[tauri::command]
pub async fn add_note_in_group(
    group_id: String,
    title: String,
    content: String,
    is_encrypted: bool,
    state: State<'_, AppState>,
) -> Result<String, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;
    
    let user_profile = find_user_profile(pool)
        .await
        .map_err(|e| format!("Failed to find user profile: {}", e))?
        .ok_or("User profile not found")?;

    let encryption_key = user_profile.note_password_hash.as_bytes();

    let note_id = create_note(&group_id, &title, &content, is_encrypted, encryption_key, pool)
        .await
        .map_err(|e| format!("Failed to add note: {}", e));

    match note_id {
        Ok(id) => Ok(id),
        Err(e) => Err(format!("Failed to add note: {}", e)),
    }
}

#[tauri::command]
pub async fn edit_note(
    note_id: String,
    title: String,
    content: String,
    is_encrypted: bool,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;
    
    let user_profile = find_user_profile(pool)
        .await
        .map_err(|e| format!("Failed to find user profile: {}", e))?
        .ok_or("User profile not found")?;

    let encryption_key = user_profile.note_password_hash.as_bytes();

    crate::db::repo_notes::update_note(note_id.as_str(), &title, &content, is_encrypted, encryption_key, pool)
        .await
        .map_err(|e| format!("Failed to edit note: {}", e))
}

#[tauri::command]
pub async fn delete_note(
    note_id: String,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;
    crate::db::repo_notes::delete_note_by_id(note_id.as_str(), pool)
        .await
        .map_err(|e| format!("Failed to delete note: {}", e))
}   
