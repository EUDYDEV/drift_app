use crate::models::{JwtClaims, PackTicketJwtClaims};
use anyhow::anyhow;
use argon2::password_hash::SaltString;
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use async_trait::async_trait;
use axum::extract::FromRequestParts;
use axum::http::{header::AUTHORIZATION, request::Parts, StatusCode};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use uuid::Uuid;

pub struct AuthUser(pub Uuid);
pub struct AuthPartner(pub Uuid);

fn extract_auth_subject(parts: &Parts) -> Result<Uuid, (StatusCode, String)> {
    let auth_header = parts
        .headers
        .get(AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .ok_or((
            StatusCode::UNAUTHORIZED,
            "Missing authorization header".to_string(),
        ))?;

    let token = auth_header.strip_prefix("Bearer ").ok_or((
        StatusCode::UNAUTHORIZED,
        "Invalid authorization header".to_string(),
    ))?;

    decode_jwt(token).map_err(|err| (StatusCode::UNAUTHORIZED, err.to_string()))
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = (StatusCode, String);

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        Ok(AuthUser(extract_auth_subject(parts)?))
    }
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthPartner
where
    S: Send + Sync,
{
    type Rejection = (StatusCode, String);

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        Ok(AuthPartner(extract_auth_subject(parts)?))
    }
}

pub fn hash_password(password: &str) -> anyhow::Result<String> {
    let salt = SaltString::generate(rand::thread_rng());
    let argon2 = Argon2::default();
    let password_hash = argon2
        .hash_password(password.as_bytes(), &salt)
        .map_err(|e| anyhow!(e.to_string()))?
        .to_string();
    Ok(password_hash)
}

pub fn verify_password(password: &str, hash: &str) -> anyhow::Result<bool> {
    let parsed_hash = PasswordHash::new(hash).map_err(|e| anyhow!(e))?;
    let argon2 = Argon2::default();
    Ok(argon2
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

pub fn create_jwt(user_id: Uuid) -> anyhow::Result<String> {
    let claims = JwtClaims {
        sub: user_id.to_string(),
        exp: chrono::Utc::now().timestamp() + (7 * 24 * 60 * 60), // 7 days
    };
    encode_claims(&claims)
}

pub fn create_pack_ticket_jwt(
    user_id: Uuid,
    ticket_id: Uuid,
    partner_id: Option<Uuid>,
    prestation_id: Option<Uuid>,
    service_type: &str,
    expires_at: chrono::DateTime<chrono::Utc>,
) -> anyhow::Result<String> {
    let claims = PackTicketJwtClaims {
        sub: user_id.to_string(),
        exp: expires_at.timestamp(),
        ticket_id: ticket_id.to_string(),
        partner_id: partner_id.map(|value| value.to_string()),
        prestation_id: prestation_id.map(|value| value.to_string()),
        service_type: service_type.to_string(),
    };
    encode_claims(&claims)
}

fn encode_claims<T: serde::Serialize>(claims: &T) -> anyhow::Result<String> {
    let secret =
        std::env::var("JWT_SECRET").unwrap_or_else(|_| "change_me_in_production".to_string());
    Ok(encode(
        &Header::default(),
        claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )?)
}

pub fn decode_jwt(token: &str) -> anyhow::Result<Uuid> {
    let secret =
        std::env::var("JWT_SECRET").unwrap_or_else(|_| "change_me_in_production".to_string());
    let data = decode::<JwtClaims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )?;
    Ok(Uuid::parse_str(&data.claims.sub)?)
}
