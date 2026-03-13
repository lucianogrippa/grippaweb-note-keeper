use crate::{AppState, db::repo_users::find_user_profile};
use tauri::State;
use anyhow::Result;
use crate::entities::profiles::UserProfile;


#[tauri::command]
pub async fn get_user_profile(
    state: State<'_, AppState>,
) -> Result<UserProfile, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;

    let profile = find_user_profile(pool).await.map_err(|e| format!("Failed to get user profile: {}", e))?;

    let user_profile: UserProfile = if let Some(profile) = profile {
        let mut cloned_profile = profile.clone();
        cloned_profile.note_password_hash = "*".to_string(); // hide the note password hash for security reasons
        cloned_profile
    } else {
        return Err("No user profile found".to_string());
    };
    
    Ok(user_profile)
}