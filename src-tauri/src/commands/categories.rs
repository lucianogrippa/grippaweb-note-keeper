use crate::{AppState, db::repo_categories::get_categories_by_user_id, db::repo_categories::new_category};
use tauri::State;
use crate::entities::categories::Category;


#[tauri::command]
pub async fn get_categories_by_user(
    user_id: String,
    state: State<'_, AppState>,
) -> Result<Vec<Category>, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;

    get_categories_by_user_id(&user_id, pool)
        .await
        .map_err(|e| format!("Failed to get categories: {}", e))
}

#[tauri::command]
pub async fn add_category(
    user_id: String,
    name: String,
    description: Option<String>,
    state: State<'_, AppState>,
) -> Result<String, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?; 

    let category_id = new_category(&user_id, &name, description.as_deref(), pool)
        .await
        .map_err(|e| format!("Failed to add category: {}", e));
    
    match category_id {
        Ok(id) => Ok(id),
        Err(e) => Err(format!("Failed to add category: {}", e)),
    }
}