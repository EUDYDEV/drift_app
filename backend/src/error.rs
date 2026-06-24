use axum::{http::StatusCode, response::IntoResponse, Json};
use serde_json::json;
use sqlx::Error as SqlxError;

#[derive(Debug)]
pub enum AppError {
    BadRequest(String),
    Conflict(String),
    UserExists,
    InvalidCredentials,
    Unauthorized,
    NotFound,
    DbError(String),
    Internal(String),
}

impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        let (status, error_message): (StatusCode, String) = match self {
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg),
            AppError::Conflict(msg) => (StatusCode::CONFLICT, msg),
            AppError::UserExists => (StatusCode::CONFLICT, "User already exists".into()),
            AppError::InvalidCredentials => {
                (StatusCode::UNAUTHORIZED, "Invalid credentials".into())
            }
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized".into()),
            AppError::NotFound => (StatusCode::NOT_FOUND, "Resource not found".into()),
            AppError::DbError(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg),
            AppError::Internal(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg),
        };

        (status, Json(json!({"error": error_message}))).into_response()
    }
}

impl From<SqlxError> for AppError {
    fn from(err: SqlxError) -> Self {
        match err {
            SqlxError::RowNotFound => AppError::NotFound,
            other => AppError::DbError(other.to_string()),
        }
    }
}

impl From<anyhow::Error> for AppError {
    fn from(err: anyhow::Error) -> Self {
        AppError::Internal(err.to_string())
    }
}
