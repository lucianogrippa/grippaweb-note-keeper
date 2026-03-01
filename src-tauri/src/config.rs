
pub struct Config {
    pub database_path: String,
    pub database_password: String,
}


impl Config {
    pub fn new() -> Self {

        // load env variables from .env file
        dotenvy::dotenv().ok();

        // load password from environment variable or use default
        let database_password = std::env::var("DATABASE_PASSWORD").unwrap_or_else(|_| "my_secret_password".to_string());
        let database_path = std::env::var("DATABASE_PATH").unwrap_or_else(|_| "notes.db".to_string());

        Self {
            database_path,
            database_password,
        }
    }
}

pub fn setup() {
    let config = Config::new();
}