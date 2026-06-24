mod auth;
mod db;
mod error;
mod models;
mod payments;
mod routes;

use axum::{routing::get, Json, Router};
use serde_json::json;
use sqlx::{migrate::Migrator, PgPool};
use std::net::SocketAddr;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

static MIGRATOR: Migrator = sqlx::migrate!("./migrations");

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .init();

    dotenvy::dotenv().ok();
    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://drift:driftpass@localhost:5432/drift_db".to_string());
    let pool = PgPool::connect(&db_url).await?;

    MIGRATOR.run(&pool).await?;

    let app = Router::new()
        .route("/health", get(health_handler))
        .nest("/auth", routes::auth_routes())
        .nest("/partners", routes::partner_routes())
        .nest("/voyages", routes::voyage_routes())
        .nest("/drivers", routes::driver_routes())
        .nest("/rides", routes::ride_routes())
        .nest("/hotels", routes::hotel_routes())
        .nest("/reservations", routes::reservation_routes())
        .nest("/payments", payments::payment_routes())
        .nest("/pack", routes::pack_routes())
        .with_state(pool.clone());

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    tracing::info!("Server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_handler() -> Json<serde_json::Value> {
    Json(json!({"ok": true}))
}
