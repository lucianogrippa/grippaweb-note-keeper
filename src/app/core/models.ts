export interface User {
  id: string;
  full_name: string;
  username?: string;
  note_password?: string;
  master_password?: string;
  created_at: string;
  updated_at: string;
}

export interface SetupData {
  full_name: string;
  note_password: string;
  master_password: string;
}
