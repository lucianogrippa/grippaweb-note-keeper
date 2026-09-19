import { invoke } from "@tauri-apps/api/core";
import { User } from "../models";
import { open } from "@tauri-apps/plugin-dialog";



export async function isDbExist(): Promise<boolean> {
  try {
    const db_exist = await invoke('is_db_exist');
    return db_exist as boolean;
  } catch (error) {
    console.error('Error checking database existence:', error);
    return false;
  }
}

export async function getUserProfile(): Promise<User | null> {

  try {
    const userProfile = await invoke("get_user_profile");

    if (!userProfile) {
      return null;
    }

    if (userProfile && typeof userProfile === 'object' && 'full_name' in userProfile && 'created_at' in userProfile && 'updated_at' in userProfile) {
      return userProfile as User;
    }

    if (userProfile && typeof userProfile === 'string') {
      open({
        title: "Profile Load Error",
        message: `Failed to load user profile. ${userProfile}.`,
        kind: "error",
        okLabel: "OK"
      });
    }
  } catch (error: any) {
    console.error('Error loading user profile:', error);
  }

  return null;

}

export async function login(master_password: string): Promise<User> {
  try {
    return await invoke("login", { master_password });
  } catch (error: any) {
    console.error('Error during login:', error);
   
    return Promise.reject(error);
  }
}

export async function register(setupData: { full_name: string; note_password: string; master_password: string }): Promise<User> {
  try {
    return await invoke("register", setupData);
  } catch (error: any) {
    console.error('Error during registration:', error);
    return Promise.reject(error);
  }
}

export async function updateUserProfile(full_name?: string): Promise<User> {
  try {
    return await invoke("save_user_profile", { fullName : full_name});
  } catch (error: any) {
    console.error('Error during user profile update:', error);
    return Promise.reject(error);
  }
}

export async function deleteUserProfile(): Promise<void> {
  try {
    await invoke("delete_user_profile");
  } catch (error: any) {
    console.error('Error during user profile deletion:', error);
    return Promise.reject(error);
  }
}

export async function resetSession(): Promise<void> {
  try {
    await invoke("reset_app");
  } catch (error) {
    console.error(' Error during session reset:', error);
    return Promise.reject(error);
  }
}
export async function logout(): Promise<void> {
  try {
    await invoke("logout");
  } catch (error) {
    console.error('Error during logout:', error);
    return Promise.reject(error);
  }
}