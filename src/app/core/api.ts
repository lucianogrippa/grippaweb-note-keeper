import { invoke } from "@tauri-apps/api/core";

export async function isDbExist(): Promise<boolean> {
  const db_exist = await invoke('is_db_exist');
  return db_exist as boolean;
}
