import { invoke } from "@tauri-apps/api/core";
import { Category } from "../data.service";

export async function getCategoriesByUser(userId: string): Promise<Category[]> {
  try {
    const categories = await invoke<Category[]>("get_categories_by_user", { userId });
    if (categories) {
      return categories;
    }
  } catch (error: any) {
    console.error('Error loading categories:', error);
  }
  return [];
}

export async function addCategory(userId: string, name: string, description: string): Promise<string> {
    try {
        const newCategoryId = await invoke<string>("add_category", { userId, name, description });
        return newCategoryId;
    } catch (error: any) {
        console.error('Error adding category:', error);
        return Promise.reject(error);
    }
}

export async function editCategory(categoryId: string, name: string, description: string): Promise<void> {
    try {
        await invoke("edit_category", { categoryId, name, description });
    } catch (error: any) {
        console.error('Error editing category:', error);
        return Promise.reject(error);
    }
  }

export async function findCategoryById(categoryId: string): Promise<Category | null> {
    try {
        const category = await invoke<Category>("find_category_by_id", { categoryId });
        return category || null;
    } catch (error: any) {
        console.error('Error finding category:', error);
        return null;
    }
}

export async function searchCategories(userId: string, query: string): Promise<Category[]> {
    try {
        const categories = await invoke<Category[]>("search_categories", { userId, query });
        return categories || [];
    } catch (error: any) {
        console.error('Error searching categories:', error);
        return [];
    }
}

export async function deleteCategoryById(categoryId: string): Promise<void> {
    try {
        await invoke("delete_category_by_id", { categoryId });
    } catch (error: any) {
        console.error('Error deleting category:', error);
        return Promise.reject(error);
    }
}
