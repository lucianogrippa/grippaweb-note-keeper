use crate::{entities::categories::Note, management::NoteManager};
use anyhow::{Context, Result};


pub async fn get_all_notes_by_group_id(
    group_id: &str,
    pool: &sqlx::Pool<sqlx::Sqlite>,
) -> Result<Vec<Note>, anyhow::Error> {
    let notes = sqlx::query_as::<_, Note>(
            "SELECT notes.id, notes.groups_id AS group_id, groups.name AS group_name, notes.title,IIF(notes.is_encrypted = 0, notes.content, '***') AS content, notes.is_encrypted, notes.created_at, notes.updated_at FROM notes JOIN groups ON notes.groups_id = groups.id WHERE notes.groups_id = ? ORDER BY notes.created_at DESC",
        )
        .bind(group_id)
        .fetch_all(pool)
        .await?;
    Ok(notes)
}

pub async fn get_note_by_id(
    note_id: &str,
    decrypt_content: bool,
    encryption_key: &[u8],
    pool: &sqlx::Pool<sqlx::Sqlite>,
) -> Result<Note, anyhow::Error> {

    if decrypt_content {
        let note = sqlx::query_as::<_, Note>(
            "SELECT notes.id, notes.groups_id AS group_id, groups.name AS group_name, notes.title, notes.content, notes.is_encrypted, notes.created_at, notes.updated_at FROM notes JOIN groups ON notes.groups_id = groups.id WHERE notes.id = ?",
        )
        .bind(note_id)
        .fetch_one(pool)
        .await
        .context("Failed to retrieve note from database")?;

        // Decrypt the content if it's encrypted
        if note.is_encrypted {
            let decrypted_content = NoteManager::decrypt_content(&note.content, encryption_key)?;
            let decrypted_note = Note {
                content: decrypted_content,
                ..note
            };
            return Ok(decrypted_note);
        }

        return Ok(note);
    } else {
        let note = sqlx::query_as::<_, Note>(
                "SELECT notes.id, notes.groups_id AS group_id, groups.name AS group_name, notes.title,  notes.content AS content, notes.is_encrypted, notes.created_at, notes.updated_at FROM notes JOIN groups ON notes.groups_id = groups.id WHERE notes.id = ?",
            )
            .bind(note_id)
            .fetch_one(pool)
            .await
            .context("Failed to retrieve note from database")?;

        Ok(note)
    }
}

pub async fn create_note(
    group_id: &str,
    title: &str,
    content: &str,
    is_encrypted: bool,
    encryption_key: &[u8],
    pool: &sqlx::Pool<sqlx::Sqlite>,
) -> Result<(), anyhow::Error> {
    let encrypted_content = if is_encrypted {
        NoteManager::encrypt_content(content, encryption_key)?
    } else {
        content.to_string()
    };

    print!("Creating note with encrypted content: {} group_id: {}", encrypted_content, group_id);
    sqlx::query("INSERT INTO notes (groups_id, title, content, is_encrypted, created_at, updated_at) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP   )")
        .bind(group_id)
        .bind(title)
        .bind(encrypted_content)
        .bind(is_encrypted)
        .execute(pool)
        .await?;
    Ok(())
}
pub async fn update_note(
    note_id: &str,
    title: &str,
    content: &str,
    is_encrypted: bool,
    encryption_key: &[u8],
    pool: &sqlx::Pool<sqlx::Sqlite>,
) -> Result<(), anyhow::Error> {
    let encrypted_content = if is_encrypted {
        NoteManager::encrypt_content(content, encryption_key)?
    } else {
        content.to_string()
    };

    sqlx::query("UPDATE notes SET title = ?, content = ?, is_encrypted = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?")
        .bind(title)
        .bind(encrypted_content)
        .bind(is_encrypted)
        .bind(note_id)
        .execute(pool)
        .await
        .context("Failed to update note in database")?;
    Ok(())
}

pub async fn delete_note_by_id(
    note_id: &str,
    pool: &sqlx::Pool<sqlx::Sqlite>,
) -> Result<(), anyhow::Error> {
    sqlx::query("DELETE FROM notes WHERE id = ?")
        .bind(note_id)
        .execute(pool)
        .await
        .context("Failed to delete note from database")?;
    Ok(())
}