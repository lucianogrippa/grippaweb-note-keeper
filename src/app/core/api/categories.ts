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