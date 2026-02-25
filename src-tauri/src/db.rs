use sqlx::sqlite::{SqliteConnectOptions, SqliteConnection};
use sqlx::{ConnectOptions, Executor};
use std::str::FromStr;

pub async fn create_encrypted_database(database_path: &str, password: &str) -> anyhow::Result<(SqliteConnection, Option<sqlx::Error>)> {
    let mut connection = SqliteConnectOptions::from_str(database_path)?
        .pragma("key", password.to_string())
        .create_if_missing(true)
        .connect()
        .await?;

    let test_result = sqlx::query("SELECT 1").fetch_optional(&mut connection).await;
    
    let _ = migrate_database_from_sql("docs/migration.sql", &mut connection).await.err();
    
    match test_result {
        Ok(_) => Ok((connection, None)),
        Err(e) => Ok((connection, Some(e))),
    }
}


async fn  migrate_database_from_sql(file_path:&str, connection: &mut SqliteConnection) -> anyhow::Result<()> {
    let sql = std::fs::read_to_string(file_path)?;
    let _ = connection.execute(sql.as_str()).await.err();
    Ok(())
}