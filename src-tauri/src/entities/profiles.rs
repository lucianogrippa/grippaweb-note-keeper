use serde::{Deserialize, Serialize};
use sqlx::FromRow;


#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserProfile {
    pub id: String,
    pub full_name: String,
    #[sqlx(rename = "password_hash")]
    pub note_password_hash: String,
    pub created_at: String,
    pub updated_at: String,
}