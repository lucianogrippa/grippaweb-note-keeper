use serde::{Deserialize, Serialize};
use sqlx::FromRow;


#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserProfile {
    pub full_name: String,
    pub note_password_hash: String,
    pub create_at: String,
    pub updated_at: String,
}