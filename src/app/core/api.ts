import { invoke } from "@tauri-apps/api/core";
import { User } from "./models";

export async function isDbExist(): Promise<boolean> {
  const db_exist = await invoke('is_db_exist');
  return db_exist as boolean;
}

export async function getUserProfile(): Promise<User | null> {
  return await invoke("get_user_profile");

}

export async function login(master_password: string): Promise<User> {
  return await invoke("login", { master_password });
}

export async function register(setupData: { full_name: string; note_password: string; master_password: string }): Promise<User> {
  return await invoke("register", setupData);
}

export async function getUserProfiles(): Promise<User[]> {
  return await invoke("get_user_profiles");
}

export async function updateUserProfile(profileData: { full_name?: string; note_password?: string; master_password?: string }): Promise<User> {
  return await invoke("update_user_profile", profileData);
}

export async function deleteUserProfile(): Promise<void> {
  await invoke("delete_user_profile");
}

export async function logout(): Promise<void> {
  await invoke("logout");
}