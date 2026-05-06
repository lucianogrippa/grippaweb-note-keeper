import { invoke } from "@tauri-apps/api/core";
import { Group } from "../data.service";

export async function loadGroupsByCategory(categoryId: string): Promise<Group[]> {
  try {
    const groups = await invoke<Group[]>("get_groups_by_category", { categoriesId:categoryId });
    if (groups) {
      return groups;
    }
  } catch (error: any) {
    console.error('Error loading groups:', error);
  }
  return [];
}

export async function createGroup(group: { name: string; categories_id: string }): Promise<Group | null> {
  try {
    const newGroup = await invoke<Group>("add_group_in_category", { categoriesId: group.categories_id, name: group.name });
    return newGroup;
  } catch (error: any) {
    console.error('Error creating group:', error);
    return null;
  }
}

export async function deleteGroup(groupId: string): Promise<boolean> {
  try {
    await invoke("delete_group", { groupId });
    return true;
  } catch (error: any) {
    throw error;
  }
}

export async function updateGroup(group: Group): Promise<Group | null> {
  try {
    const updatedGroup = await invoke<Group>("edit_group", { groupId: group.id, name: group.name });
    return updatedGroup;
  } catch (error: any) {
    console.error('Error updating group:', error);
    return null;
  }
}