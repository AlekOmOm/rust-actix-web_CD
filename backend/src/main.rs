use actix_web::{get, web, App, HttpServer, Responder};

use env_logger::Env;
use sqlx::sqlite::SqlitePoolOptions; // Import Pool
use std::env;

#[get("/")]
async fn hello() -> impl Responder {
    "Hello from Actix Backend!"
}

#[get("/config")]
async fn config() -> impl Responder {
    let db_url = env::var("DATABASE_URL").unwrap_or_else(|_| "Not Set".to_string());
    let port = env::var("APP_PORT").unwrap_or_else(|_| "Not Set".to_string());
    format!("DB URL: {}, Internal Port: {}", db_url, port)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(Env::default().default_filter_or("info"));

    #[cfg(debug_assertions)]
    dotenv::dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let port_str = env::var("APP_PORT").unwrap_or_else(|_| "8080".to_string());
    let port = port_str
        .parse::<u16>()
        .expect("APP_PORT must be a valid port number");

    log::info!("Starting backend server...");
    log::info!("Internal Port: {}", port);
    log::info!("Database URL: {}", database_url);

    // --- Database Connection & Migration ---
    // Ensure the directory exists before connecting (important for volume mounts)
    if database_url.starts_with("sqlite:") {
        let db_path_str = database_url.trim_start_matches("sqlite:");
        if let Some(parent_dir) = std::path::Path::new(db_path_str).parent() {
            if !parent_dir.exists() {
                log::info!("Creating database directory: {:?}", parent_dir);
                std::fs::create_dir_all(parent_dir)?;
            }
        }
    }

    // Create connection pool
    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        // `connect` will create the DB file if it doesn't exist
        .connect(&database_url)
        .await
        .expect("Failed to create SQLite connection pool.");
    log::info!("Database connection pool created.");

    // --- Run Migrations ---
    log::info!("Running database migrations...");
    // Point to the migrations directory relative to Cargo.toml
    sqlx::migrate!("../database/migrations") // Adjust path if needed
        .run(&pool)
        .await
        .expect("Failed to run database migrations");
    log::info!("Database migrations applied successfully.");
    // --- End Database Setup ---

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone())) // Share pool with handlers
            .service(hello)
            .service(config)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
