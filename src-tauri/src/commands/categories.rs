use crate::{AppState, db::repo_categories::{delete_category, edit_category, find_by_name_or_description, get_categories_by_user_id, get_category_by_id, new_category}};
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

#[tauri::command]
pub async fn update_category(
    category_id: String,
    name: String,
    description: String,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?; 

    edit_category(category_id.as_str(), Some(&name), Some(&description), pool)
        .await
        .map_err(|e| format!("Failed to update category: {}", e))?;

    Ok(())
}

#[tauri::command]
pub async fn find_category_by_id(
    category_id: String,
    state: State<'_, AppState>,
) -> Result<Category, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;

    let category =  get_category_by_id(&category_id, pool)
        .await
        .map_err(|e| format!("Failed to get category: {}", e));

    match category {
        Ok(cat) => Ok(cat),
        Err(e) => Err(format!("Failed to get category: {}", e))
    }
}

#[tauri::command]
pub async fn search_categories(
    user_id: String,
    query: String,
    state: State<'_, AppState>,
) -> Result<Vec<Category>, String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;

   let result_categories =  find_by_name_or_description(&user_id, &query, pool)
        .await
        .map_err(|e| format!("Failed to get categories: {}", e));

    Ok(result_categories?)
}

#[tauri::command]
pub async fn delete_category_by_id(
    category_id: String,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let pool = state.pool.read().await;
    let pool = pool.as_ref().ok_or("Database pool not initialized")?;

   delete_category(&category_id, pool)
        .await
        .map_err(|e| format!("Failed to delete category: {}", e))?;

    Ok(())
}