use actix_web::{get, web, App, HttpServer, Responder};
//use actix_web::http::header;
use env_logger::Env;
//use sqlx::sqlite::SqlitePoolOptions; // Import Pool
use std::env;
use std::path::Path;

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

    if database_url.starts_with("sqlite:") {
        
        let db_path_str = database_url.trim_start_matches("sqlite:");
        let db_path = Path::new(db_path_str);

        if let Some(parent_dir) = db_path.parent() {
            if !parent_dir.exists() {
                log::info!("Creating database directory: {:?}", parent_dir);
                // Use std::fs::create_dir_all which is idempotent (doesn't error if dir exists)
                std::fs::create_dir_all(parent_dir)?; // The '?' propagates potential I/O errors
                log::info!("Database directory created (or already exists).");
            }
        }
    }

       // Create connection pool
    //    let pool = SqlitePoolOptions::new()
    //         .max_connections(5)
    //         .connect(&database_url) // creates the file if not exists (requires directory to exist!)
    //         .await
    //         .expect("Failed to create SQLite connection pool."); // Will panic if dir doesn't exist or permissions fail
    //     log::info!("Database connection pool created.");

    HttpServer::new(move || {
        App::new()
            //.app_data(web::Data::new(pool.clone())) // Share pool with handlers
            .service(hello)
            .service(config)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
