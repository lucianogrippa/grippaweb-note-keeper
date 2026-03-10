use crate::AppState;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use tauri::State;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserProfile {
    full_name: String,
    note_password_hash: String,
    create_at: String,
    updated_at: String,
}

#[tauri::command]
pub async fn get_user_profiles(
    state: State<'_, AppState>,
) -> Result<UserProfile, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;

    let profile = sqlx::query_as::<_, UserProfile>("SELECT * FROM user_profile LIMIT 1")
        .fetch_optional(pool)
        .await
        .map_err(|e| format!("Failed to get profiles {}", e))?;

    let user_profile: UserProfile = if let Some(profile) = profile {
        let mut cloned_profile = profile.clone();
        cloned_profile.note_password_hash = "*".to_string(); // hide the note password hash for security reasons
        cloned_profile
    } else {
        return Err("No user profile found".to_string());
    };
    
    Ok(user_profile)
}