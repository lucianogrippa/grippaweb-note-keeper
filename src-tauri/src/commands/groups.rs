use tauri::State;

use crate::{AppState, db::repo_groups::{get_groups_by_category_id, new_group}, entities::categories::Group};



#[tauri::command]
pub async fn get_groups_by_category(
    categories_id: String,
    state: State<'_, AppState>,
) -> Result<Vec<Group>, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;

    get_groups_by_category_id(&categories_id, pool)
        .await
        .map_err(|e| format!("Failed to get groups: {}", e))
}

#[tauri::command]
pub async fn find_group_by_id(
    group_id: String,
    state: State<'_, AppState>,
) -> Result<Group, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;   

    crate::db::repo_groups::get_group_by_id(group_id.as_str(), pool)
        .await
        .map_err(|e| format!("Failed to find group: {}", e))
}   


#[tauri::command]
pub async fn add_group_in_category(
    categories_id: String,
    name: String,
    state: State<'_, AppState>,
) -> Result<String, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?; 

    let group_id = new_group(&categories_id, &name, pool)
        .await
        .map_err(|e| format!("Failed to add group: {}", e));
    
    match group_id {
        Ok(id) => Ok(id.to_string()),
        Err(e) => Err(format!("Failed to add group: {}", e)),
    }
}

#[tauri::command]
pub async fn edit_group(
    group_id: String,
    name: String,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?; 

    crate::db::repo_groups::edit_group(group_id.as_str(), &name, pool)
        .await
        .map_err(|e| format!("Failed to edit group: {}", e))?;

    Ok(())
}

#[tauri::command]
pub async fn delete_group(
    group_id: String,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;   

    crate::db::repo_groups::delete_group(group_id.as_str(), pool)
        .await
        .map_err(|e| format!("Failed to delete group: {}", e))?;    

    Ok(())
}
