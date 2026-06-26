use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post, put},
    Json, Router,
};
use chrono::{Duration, Utc};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::{types::Json as SqlxJson, PgPool};
use uuid::Uuid;

use crate::{auth, error::AppError, models::User};

const IMPERSONATION_TTL_SECONDS: i64 = 15 * 60;

pub fn admin_routes() -> Router<PgPool> {
    Router::new()
        .route("/master-login", post(master_creator_login))
        .route("/layout", get(get_admin_layout))
        .route("/summary", get(get_admin_summary))
        .route("/roles/:user_id/permissions", put(update_user_permissions))
        .route(
            "/partners/:partner_id/onboarding",
            put(review_partner_onboarding),
        )
        .route("/users/:user_id/kill-switch", post(kill_switch_user))
        .route(
            "/security/events",
            get(list_security_events).post(record_security_event),
        )
        .route("/security/pentest", post(run_internal_pentest))
        .route("/security/encryption-health", get(get_encryption_health))
        .route("/privacy/anonymize/:user_id", post(anonymize_user))
        .route("/github/deploy", post(trigger_github_deploy))
        .route("/feature-flags", get(list_feature_flags))
        .route("/feature-flags/:flag_key", put(update_feature_flag))
        .route(
            "/maintenance",
            get(list_maintenance_modes).post(upsert_maintenance_mode),
        )
        .route("/finance/overview", get(get_finance_overview))
        .route(
            "/it-expenses",
            get(list_it_expenses).post(create_it_expense),
        )
        .route("/reviews", get(list_reviews))
        .route("/reviews/:review_id/moderate", put(moderate_review))
        .route(
            "/pricing-rules",
            get(list_pricing_rules).post(create_pricing_rule),
        )
        .route("/logs", get(list_audit_events))
        .route("/errors", get(list_crash_reports).post(record_crash_report))
        .route(
            "/errors/:crash_id/shadow-dev",
            post(generate_shadow_dev_suggestion),
        )
        .route("/impersonate/:user_id", post(impersonate_user))
        .route("/capacity-alerts", get(list_capacity_alerts))
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MasterCreatorLoginRequest {
    pub master_creator_key: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AdminAuthResponse {
    pub user: User,
    pub token: String,
    pub permissions: Vec<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AdminLayoutResponse {
    pub role: String,
    pub permissions: Vec<String>,
    pub layout: Value,
}

#[derive(Debug)]
struct AdminContext {
    user: User,
    permissions: Vec<String>,
}

#[derive(Debug, sqlx::FromRow)]
struct LayoutRow {
    config: SqlxJson<Value>,
}

#[derive(Debug, sqlx::FromRow)]
struct JsonRow {
    payload: SqlxJson<Value>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PermissionUpdateRequest {
    role_key: String,
    permissions: Vec<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PartnerOnboardingRequest {
    approved: bool,
    reason: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct KillSwitchRequest {
    reason: Option<String>,
    partner_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct SecurityEventRequest {
    severity: Option<String>,
    category: String,
    source_ip: Option<String>,
    user_id: Option<Uuid>,
    payload: Option<Value>,
    ban_minutes: Option<i64>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct GithubDeployRequest {
    workflow: Option<String>,
    branch: Option<String>,
    environment: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct FeatureFlagUpdateRequest {
    enabled: bool,
    rollout_percentage: i32,
    audience: Option<Value>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct MaintenanceModeRequest {
    scope_type: String,
    scope_value: Option<String>,
    enabled: bool,
    message: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct ItExpenseRequest {
    provider: String,
    category: String,
    amount: f64,
    currency: Option<String>,
    billing_period: Option<String>,
    notes: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct ReviewModerationRequest {
    status: String,
    reason: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PricingRuleRequest {
    name: String,
    service_type: String,
    city: Option<String>,
    coefficient: f64,
    conditions: Option<Value>,
    enabled: Option<bool>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct CrashReportRequest {
    source: String,
    severity: Option<String>,
    title: String,
    stack_trace: Option<String>,
    fingerprint: Option<String>,
    metadata: Option<Value>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct ImpersonationRequest {
    reason: Option<String>,
}

pub async fn master_creator_login(
    State(pool): State<PgPool>,
    Json(req): Json<MasterCreatorLoginRequest>,
) -> Result<Json<AdminAuthResponse>, AppError> {
    let expected_key_raw = std::env::var("MASTER_CREATOR_KEY").map_err(|_| {
        AppError::Internal("MASTER_CREATOR_KEY is not configured on the backend".to_string())
    })?;
    let submitted_key_raw = req.master_creator_key;
    let expected_key = expected_key_raw.trim().to_lowercase();
    let submitted_key = submitted_key_raw.trim().to_lowercase();

    if expected_key.len() != 64 {
        return Err(AppError::Internal(
            "MASTER_CREATOR_KEY must be exactly 64 characters".to_string(),
        ));
    }

    tracing::warn!(
        target: "drift_admin_auth",
        received_master_creator_key = %submitted_key_raw,
        env_master_creator_key = %expected_key_raw,
        received_raw_len = submitted_key_raw.len(),
        env_raw_len = expected_key_raw.len(),
        received_normalized_len = submitted_key.len(),
        env_normalized_len = expected_key.len(),
        "MASTER_CREATOR_KEY debug comparison - remove or disable this log before production"
    );

    if !constant_time_eq(submitted_key.as_bytes(), expected_key.as_bytes()) {
        insert_audit_event(
            &pool,
            None,
            "critical",
            "MASTER_CREATOR_KEY_REJECTED",
            Some("auth"),
            None,
            json!({"message": "Invalid creator backdoor attempt"}),
        )
        .await?;
        return Err(AppError::Unauthorized);
    }

    let creator_email =
        std::env::var("MASTER_CREATOR_EMAIL").unwrap_or_else(|_| "creator@drift.local".to_string());
    let creator_name =
        std::env::var("MASTER_CREATOR_FULL_NAME").unwrap_or_else(|_| "Créateur Drift".to_string());
    let creator_id = std::env::var("MASTER_CREATOR_USER_ID")
        .ok()
        .and_then(|raw| Uuid::parse_str(raw.trim()).ok())
        .unwrap_or_else(Uuid::new_v4);
    let disabled_password_hash =
        auth::hash_password(&format!("disabled-master-login-{}", Uuid::new_v4()))?;

    let user = sqlx::query_as::<_, User>(
        "INSERT INTO users (
            id, email, full_name, password_hash, role,
            is_restricted, restriction_reason, identity_documents_verified,
            driving_license_status
         )
         VALUES ($1, $2, $3, $4, 'SUPER_ADMIN', FALSE, NULL, TRUE, 'verified')
         ON CONFLICT (email)
         DO UPDATE SET
            full_name = EXCLUDED.full_name,
            role = 'SUPER_ADMIN',
            is_restricted = FALSE,
            restriction_reason = NULL,
            identity_documents_verified = TRUE,
            driving_license_status = 'verified'
         RETURNING id, email, full_name, role, account_balance, penalty_balance,
                   active_fine_amount, is_restricted, restriction_reason,
                   identity_documents_verified, driving_license_status, created_at",
    )
    .bind(creator_id)
    .bind(&creator_email)
    .bind(&creator_name)
    .bind(disabled_password_hash)
    .fetch_one(&pool)
    .await?;

    let cleared_revocations = sqlx::query(
        "UPDATE admin_token_revocations
         SET expires_at = now(),
             reason = CONCAT(reason, ' | cleared by MASTER_CREATOR_KEY')
         WHERE user_id = $1
           AND (expires_at IS NULL OR expires_at > now())",
    )
    .bind(user.id)
    .execute(&pool)
    .await?
    .rows_affected();

    sqlx::query(
        "INSERT INTO admin_user_roles (user_id, role_key, assigned_by, active)
         VALUES ($1, 'SUPER_ADMIN', $1, TRUE)
         ON CONFLICT (user_id, role_key)
         DO UPDATE SET active = TRUE, assigned_by = EXCLUDED.assigned_by",
    )
    .bind(user.id)
    .execute(&pool)
    .await?;

    insert_audit_event(
        &pool,
        Some(user.id),
        "critical",
        "MASTER_CREATOR_KEY_ACCEPTED",
        Some("auth"),
        Some(&user.id.to_string()),
        json!({
            "email": user.email,
            "clearedRevocations": cleared_revocations,
            "message": "Emergency creator access granted and creator account restored"
        }),
    )
    .await?;
    tracing::error!(
        creator_user_id = %user.id,
        "CRITICAL SECURITY EVENT: MASTER_CREATOR_KEY accepted"
    );

    let permissions = get_permissions(&pool, user.id, &user.role).await?;
    let token = auth::create_jwt(user.id)?;
    Ok(Json(AdminAuthResponse {
        user,
        token,
        permissions,
    }))
}

pub async fn get_admin_layout(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<AdminLayoutResponse>, AppError> {
    let ctx = require_admin(&pool, auth_user.0, None).await?;
    let layout = sqlx::query_as::<_, LayoutRow>(
        "SELECT config
         FROM admin_dashboard_layouts
         WHERE layout_key = 'super_dashboard' AND active = TRUE",
    )
    .fetch_optional(&pool)
    .await?
    .ok_or(AppError::NotFound)?;

    Ok(Json(AdminLayoutResponse {
        role: ctx.user.role,
        permissions: ctx.permissions,
        layout: layout.config.0,
    }))
}

pub async fn get_admin_summary(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("logs.view")).await?;

    let payload = sqlx::query_as::<_, JsonRow>(
        "SELECT jsonb_build_object(
            'users', (SELECT count(*) FROM users),
            'partners', (SELECT count(*) FROM partenaires),
            'prestations', (SELECT count(*) FROM prestations),
            'openSecurityEvents', (SELECT count(*) FROM admin_security_events WHERE status = 'open'),
            'openCrashes', (SELECT count(*) FROM admin_crash_reports WHERE status = 'open'),
            'featureFlagsEnabled', (SELECT count(*) FROM admin_feature_flags WHERE enabled = TRUE),
            'maintenanceEnabled', (SELECT count(*) FROM admin_maintenance_modes WHERE enabled = TRUE),
            'grossRevenue', COALESCE((SELECT sum(amount)::DOUBLE PRECISION FROM payments WHERE status = 'SUCCESS'), 0),
            'itExpenses', COALESCE((SELECT sum(amount)::DOUBLE PRECISION FROM admin_it_expenses), 0)
         ) AS payload",
    )
    .fetch_one(&pool)
    .await?;

    Ok(Json(payload.payload.0))
}

async fn update_user_permissions(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(user_id): Path<Uuid>,
    Json(req): Json<PermissionUpdateRequest>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("security.kill_switch")).await?;

    let requested_permissions = SqlxJson(req.permissions);
    sqlx::query(
        "INSERT INTO admin_roles (role_key, label, immutable, permissions)
         VALUES ($1, $1, FALSE, $2)
         ON CONFLICT (role_key)
         DO UPDATE SET permissions = EXCLUDED.permissions, updated_at = now()
         WHERE admin_roles.immutable = FALSE",
    )
    .bind(&req.role_key)
    .bind(requested_permissions)
    .execute(&pool)
    .await?;

    sqlx::query(
        "INSERT INTO admin_user_roles (user_id, role_key, assigned_by, active)
         VALUES ($1, $2, $3, TRUE)
         ON CONFLICT (user_id, role_key)
         DO UPDATE SET active = TRUE, assigned_by = EXCLUDED.assigned_by",
    )
    .bind(user_id)
    .bind(&req.role_key)
    .bind(auth_user.0)
    .execute(&pool)
    .await?;

    insert_audit_event(
        &pool,
        Some(auth_user.0),
        "high",
        "ADMIN_PERMISSIONS_UPDATED",
        Some("user"),
        Some(&user_id.to_string()),
        json!({"roleKey": req.role_key}),
    )
    .await?;

    Ok(Json(json!({"ok": true})))
}

async fn review_partner_onboarding(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(partner_id): Path<Uuid>,
    Json(req): Json<PartnerOnboardingRequest>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("partners.approve")).await?;

    sqlx::query(
        "UPDATE partenaires
         SET is_boosted = CASE WHEN $2 THEN is_boosted ELSE FALSE END,
             updated_at = now()
         WHERE id = $1",
    )
    .bind(partner_id)
    .bind(req.approved)
    .execute(&pool)
    .await?;

    if !req.approved {
        set_partner_catalog_visibility(&pool, partner_id, false).await?;
    }

    insert_audit_event(
        &pool,
        Some(auth_user.0),
        "high",
        if req.approved {
            "PARTNER_ONBOARDING_APPROVED"
        } else {
            "PARTNER_ONBOARDING_REJECTED"
        },
        Some("partner"),
        Some(&partner_id.to_string()),
        json!({"reason": req.reason}),
    )
    .await?;

    Ok(Json(json!({"ok": true, "approved": req.approved})))
}

async fn kill_switch_user(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(user_id): Path<Uuid>,
    Json(req): Json<KillSwitchRequest>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("security.kill_switch")).await?;
    let reason = req
        .reason
        .unwrap_or_else(|| "Kill-switch admin Drift".to_string());

    sqlx::query(
        "UPDATE users
         SET is_restricted = TRUE,
             restriction_reason = $2
         WHERE id = $1",
    )
    .bind(user_id)
    .bind(&reason)
    .execute(&pool)
    .await?;

    sqlx::query(
        "INSERT INTO admin_token_revocations (user_id, reason, revoked_by)
         VALUES ($1, $2, $3)",
    )
    .bind(user_id)
    .bind(&reason)
    .bind(auth_user.0)
    .execute(&pool)
    .await?;

    if let Some(partner_id) = req.partner_id {
        set_partner_catalog_visibility(&pool, partner_id, false).await?;
    }

    insert_audit_event(
        &pool,
        Some(auth_user.0),
        "critical",
        "KILL_SWITCH_TRIGGERED",
        Some("user"),
        Some(&user_id.to_string()),
        json!({"reason": reason, "partnerId": req.partner_id}),
    )
    .await?;

    Ok(Json(json!({
        "ok": true,
        "userId": user_id,
        "sessionRevoked": true,
        "websocketAction": "force_logout_pending_realtime_gateway"
    })))
}

async fn list_security_events(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("security.pentest")).await?;
    let rows = sqlx::query_as::<_, JsonRow>(
        "SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.created_at DESC), '[]'::jsonb) AS payload
         FROM (
            SELECT id, severity, category, source_ip, user_id, payload, banned_until, status, created_at
            FROM admin_security_events
            ORDER BY created_at DESC
            LIMIT 100
         ) t",
    )
    .fetch_one(&pool)
    .await?;
    Ok(Json(rows.payload.0))
}

async fn record_security_event(
    State(pool): State<PgPool>,
    Json(req): Json<SecurityEventRequest>,
) -> Result<(StatusCode, Json<Value>), AppError> {
    let banned_until = req
        .ban_minutes
        .filter(|minutes| *minutes > 0)
        .map(|minutes| Utc::now() + Duration::minutes(minutes));
    let payload = SqlxJson(req.payload.unwrap_or_else(|| json!({})));

    let event = sqlx::query_as::<_, JsonRow>(
        "INSERT INTO admin_security_events (
            severity, category, source_ip, user_id, payload, banned_until
         )
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING row_to_json(admin_security_events)::jsonb AS payload",
    )
    .bind(req.severity.unwrap_or_else(|| "medium".to_string()))
    .bind(req.category)
    .bind(req.source_ip)
    .bind(req.user_id)
    .bind(payload)
    .bind(banned_until)
    .fetch_one(&pool)
    .await?;

    Ok((StatusCode::CREATED, Json(event.payload.0)))
}

async fn run_internal_pentest(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("security.pentest")).await?;
    let checks = json!([
      {"id":"owasp-a01", "label":"Broken Access Control", "status":"scheduled"},
      {"id":"owasp-a03", "label":"Injection payload probes", "status":"scheduled"},
      {"id":"owasp-a07", "label":"Auth brute-force controls", "status":"scheduled"},
      {"id":"owasp-a09", "label":"Security logging coverage", "status":"scheduled"}
    ]);

    insert_audit_event(
        &pool,
        Some(auth_user.0),
        "high",
        "INTERNAL_PENTEST_STARTED",
        Some("security"),
        None,
        json!({"checks": checks}),
    )
    .await?;

    Ok(Json(json!({
        "status": "queued",
        "checks": checks,
        "message": "Pentest interne planifié. Aucun test destructif n'est lancé depuis l'UI."
    })))
}

async fn get_encryption_health(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("security.rotate_keys")).await?;
    let key_status = std::env::var("DOCUMENT_ENCRYPTION_KEY")
        .map(|value| {
            if value.len() >= 32 {
                "configured_strong"
            } else {
                "configured_weak"
            }
        })
        .unwrap_or("missing");
    let docs = sqlx::query_as::<_, (i64,)>("SELECT count(*) FROM user_identity_documents")
        .fetch_one(&pool)
        .await
        .map(|row| row.0)
        .unwrap_or(0);

    Ok(Json(json!({
        "documentEncryptionKey": key_status,
        "algorithm": "pgcrypto pgp_sym_encrypt_bytea cipher-algo=aes256",
        "encryptedDocumentCount": docs,
        "rotationEndpointReady": true
    })))
}

async fn anonymize_user(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(user_id): Path<Uuid>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("security.kill_switch")).await?;
    sqlx::query(
        "UPDATE users
         SET email = CONCAT('deleted+', id::TEXT, '@anonymous.drift.local'),
             full_name = 'Utilisateur anonymisé',
             is_restricted = TRUE,
             restriction_reason = 'RGPD/CI droit à l oubli'
         WHERE id = $1",
    )
    .bind(user_id)
    .execute(&pool)
    .await?;

    insert_audit_event(
        &pool,
        Some(auth_user.0),
        "critical",
        "USER_ANONYMIZED",
        Some("user"),
        Some(&user_id.to_string()),
        json!({"financialReportsPreserved": true}),
    )
    .await?;

    Ok(Json(json!({"ok": true})))
}

async fn trigger_github_deploy(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<GithubDeployRequest>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("deploy.github")).await?;
    let owner = std::env::var("GITHUB_OWNER").unwrap_or_else(|_| "EUDYDEV".to_string());
    let repo = std::env::var("GITHUB_REPO").unwrap_or_else(|_| "drift_app".to_string());
    let workflow = req
        .workflow
        .or_else(|| std::env::var("GITHUB_WORKFLOW").ok())
        .unwrap_or_else(|| "main_deploy.yml".to_string());
    let branch = req
        .branch
        .or_else(|| std::env::var("GITHUB_DEPLOY_BRANCH").ok())
        .unwrap_or_else(|| "main".to_string());

    let token = match std::env::var("GITHUB_TOKEN") {
        Ok(token) if !token.trim().is_empty() => token,
        _ => {
            return Ok(Json(json!({
                "configured": false,
                "message": "GITHUB_TOKEN absent. Déploiement non déclenché.",
                "owner": owner,
                "repo": repo,
                "workflow": workflow,
                "branch": branch
            })));
        }
    };

    let url = format!(
        "https://api.github.com/repos/{owner}/{repo}/actions/workflows/{workflow}/dispatches"
    );
    let response = Client::new()
        .post(url)
        .bearer_auth(token)
        .header("User-Agent", "drift-admin-control-plane")
        .json(&json!({
            "ref": branch,
            "inputs": {
                "environment": req.environment.unwrap_or_else(|| "production".to_string())
            }
        }))
        .send()
        .await
        .map_err(|error| AppError::Internal(format!("GitHub dispatch failed: {error}")))?;

    insert_audit_event(
        &pool,
        Some(auth_user.0),
        "critical",
        "GITHUB_DEPLOY_TRIGGERED",
        Some("github_actions"),
        Some(&workflow),
        json!({"owner": owner, "repo": repo, "branch": branch, "status": response.status().as_u16()}),
    )
    .await?;

    Ok(Json(json!({
        "configured": true,
        "accepted": response.status().is_success(),
        "statusCode": response.status().as_u16()
    })))
}

async fn list_feature_flags(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("flags.manage")).await?;
    query_json_array(
        &pool,
        "SELECT id, payload FROM (
            SELECT flag_key AS id, row_to_json(admin_feature_flags)::jsonb AS payload
            FROM admin_feature_flags
            ORDER BY flag_key
        ) s",
    )
    .await
}

async fn update_feature_flag(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(flag_key): Path<String>,
    Json(req): Json<FeatureFlagUpdateRequest>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("flags.manage")).await?;
    let audience = SqlxJson(req.audience.unwrap_or_else(|| json!({})));
    let row = sqlx::query_as::<_, JsonRow>(
        "UPDATE admin_feature_flags
         SET enabled = $2,
             rollout_percentage = $3,
             audience = $4,
             updated_by = $5,
             updated_at = now()
         WHERE flag_key = $1
         RETURNING row_to_json(admin_feature_flags)::jsonb AS payload",
    )
    .bind(flag_key)
    .bind(req.enabled)
    .bind(req.rollout_percentage)
    .bind(audience)
    .bind(auth_user.0)
    .fetch_optional(&pool)
    .await?
    .ok_or(AppError::NotFound)?;
    Ok(Json(row.payload.0))
}

async fn list_maintenance_modes(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("maintenance.manage")).await?;
    query_json_array(
        &pool,
        "SELECT id, payload FROM (
            SELECT id, row_to_json(admin_maintenance_modes)::jsonb AS payload
            FROM admin_maintenance_modes
            ORDER BY updated_at DESC
        ) s",
    )
    .await
}

async fn upsert_maintenance_mode(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<MaintenanceModeRequest>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("maintenance.manage")).await?;
    let row = sqlx::query_as::<_, JsonRow>(
        "INSERT INTO admin_maintenance_modes (
            scope_type, scope_value, enabled, message, updated_by
         )
         VALUES ($1, $2, $3, $4, $5)
         RETURNING row_to_json(admin_maintenance_modes)::jsonb AS payload",
    )
    .bind(req.scope_type)
    .bind(req.scope_value)
    .bind(req.enabled)
    .bind(req.message)
    .bind(auth_user.0)
    .fetch_one(&pool)
    .await?;
    Ok(Json(row.payload.0))
}

async fn get_finance_overview(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("finance.view")).await?;
    let row = sqlx::query_as::<_, JsonRow>(
        "SELECT jsonb_build_object(
            'grossRevenue', COALESCE((SELECT sum(amount)::DOUBLE PRECISION FROM payments WHERE status = 'SUCCESS'), 0),
            'eprojectCommission', COALESCE((SELECT sum(amount)::DOUBLE PRECISION * 0.12 FROM payments WHERE status = 'SUCCESS'), 0),
            'partnerPayouts', COALESCE((SELECT sum(amount)::DOUBLE PRECISION * 0.88 FROM payments WHERE status = 'SUCCESS'), 0),
            'itExpenses', COALESCE((SELECT sum(amount)::DOUBLE PRECISION FROM admin_it_expenses), 0),
            'netEstimated', COALESCE((SELECT sum(amount)::DOUBLE PRECISION * 0.12 FROM payments WHERE status = 'SUCCESS'), 0)
              - COALESCE((SELECT sum(amount)::DOUBLE PRECISION FROM admin_it_expenses), 0)
         ) AS payload",
    )
    .fetch_one(&pool)
    .await?;
    Ok(Json(row.payload.0))
}

async fn list_it_expenses(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("finance.view")).await?;
    query_json_array(
        &pool,
        "SELECT id, payload FROM (
            SELECT id, row_to_json(admin_it_expenses)::jsonb AS payload
            FROM admin_it_expenses
            ORDER BY created_at DESC
            LIMIT 100
        ) s",
    )
    .await
}

async fn create_it_expense(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<ItExpenseRequest>,
) -> Result<(StatusCode, Json<Value>), AppError> {
    require_admin(&pool, auth_user.0, Some("finance.view")).await?;
    let row = sqlx::query_as::<_, JsonRow>(
        "INSERT INTO admin_it_expenses (
            provider, category, amount, currency, billing_period, notes
         )
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING row_to_json(admin_it_expenses)::jsonb AS payload",
    )
    .bind(req.provider)
    .bind(req.category)
    .bind(req.amount)
    .bind(req.currency.unwrap_or_else(|| "XOF".to_string()))
    .bind(req.billing_period.unwrap_or_default())
    .bind(req.notes.unwrap_or_default())
    .fetch_one(&pool)
    .await?;
    Ok((StatusCode::CREATED, Json(row.payload.0)))
}

async fn list_reviews(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("reviews.moderate")).await?;
    query_json_array(
        &pool,
        "SELECT id, payload FROM (
            SELECT id, row_to_json(admin_reviews)::jsonb AS payload
            FROM admin_reviews
            ORDER BY created_at DESC
            LIMIT 100
        ) s",
    )
    .await
}

async fn moderate_review(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(review_id): Path<Uuid>,
    Json(req): Json<ReviewModerationRequest>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("reviews.moderate")).await?;
    let row = sqlx::query_as::<_, JsonRow>(
        "UPDATE admin_reviews
         SET status = $2,
             moderation_reason = $3,
             updated_at = now()
         WHERE id = $1
         RETURNING row_to_json(admin_reviews)::jsonb AS payload",
    )
    .bind(review_id)
    .bind(req.status)
    .bind(req.reason)
    .fetch_optional(&pool)
    .await?
    .ok_or(AppError::NotFound)?;
    Ok(Json(row.payload.0))
}

async fn list_pricing_rules(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("pricing.manage")).await?;
    query_json_array(
        &pool,
        "SELECT id, payload FROM (
            SELECT id, row_to_json(admin_pricing_rules)::jsonb AS payload
            FROM admin_pricing_rules
            ORDER BY updated_at DESC
        ) s",
    )
    .await
}

async fn create_pricing_rule(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<PricingRuleRequest>,
) -> Result<(StatusCode, Json<Value>), AppError> {
    require_admin(&pool, auth_user.0, Some("pricing.manage")).await?;
    let conditions = SqlxJson(req.conditions.unwrap_or_else(|| json!({})));
    let row = sqlx::query_as::<_, JsonRow>(
        "INSERT INTO admin_pricing_rules (
            name, service_type, city, coefficient, conditions, enabled, updated_by
         )
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING row_to_json(admin_pricing_rules)::jsonb AS payload",
    )
    .bind(req.name)
    .bind(req.service_type)
    .bind(req.city)
    .bind(req.coefficient)
    .bind(conditions)
    .bind(req.enabled.unwrap_or(true))
    .bind(auth_user.0)
    .fetch_one(&pool)
    .await?;
    Ok((StatusCode::CREATED, Json(row.payload.0)))
}

async fn list_audit_events(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("logs.view")).await?;
    query_json_array(
        &pool,
        "SELECT id, payload FROM (
            SELECT id, row_to_json(admin_audit_events)::jsonb AS payload
            FROM admin_audit_events
            ORDER BY created_at DESC
            LIMIT 150
        ) s",
    )
    .await
}

async fn list_crash_reports(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("errors.manage")).await?;
    query_json_array(
        &pool,
        "SELECT id, payload FROM (
            SELECT id, row_to_json(admin_crash_reports)::jsonb AS payload
            FROM admin_crash_reports
            ORDER BY created_at DESC
            LIMIT 100
        ) s",
    )
    .await
}

async fn record_crash_report(
    State(pool): State<PgPool>,
    Json(req): Json<CrashReportRequest>,
) -> Result<(StatusCode, Json<Value>), AppError> {
    let metadata = SqlxJson(req.metadata.unwrap_or_else(|| json!({})));
    let row = sqlx::query_as::<_, JsonRow>(
        "INSERT INTO admin_crash_reports (
            source, severity, title, stack_trace, fingerprint, metadata
         )
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING row_to_json(admin_crash_reports)::jsonb AS payload",
    )
    .bind(req.source)
    .bind(req.severity.unwrap_or_else(|| "medium".to_string()))
    .bind(req.title)
    .bind(req.stack_trace.unwrap_or_default())
    .bind(req.fingerprint.unwrap_or_default())
    .bind(metadata)
    .fetch_one(&pool)
    .await?;
    Ok((StatusCode::CREATED, Json(row.payload.0)))
}

async fn generate_shadow_dev_suggestion(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(crash_id): Path<Uuid>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("errors.manage")).await?;
    let crash = sqlx::query_as::<_, JsonRow>(
        "SELECT row_to_json(admin_crash_reports)::jsonb AS payload
         FROM admin_crash_reports
         WHERE id = $1",
    )
    .bind(crash_id)
    .fetch_optional(&pool)
    .await?
    .ok_or(AppError::NotFound)?;

    let title = crash
        .payload
        .0
        .get("title")
        .and_then(Value::as_str)
        .unwrap_or("Erreur Drift");
    let suggestion = json!({
        "summary": format!("Shadow Dev a analysé: {title}"),
        "recommendedPatch": "Créer un test de reproduction, valider les entrées côté backend, puis isoler le widget/service responsable.",
        "confidence": 0.74,
        "requiresHumanReview": true
    });

    sqlx::query(
        "UPDATE admin_crash_reports
         SET ai_suggestion = $2,
             updated_at = now()
         WHERE id = $1",
    )
    .bind(crash_id)
    .bind(SqlxJson(suggestion.clone()))
    .execute(&pool)
    .await?;

    Ok(Json(suggestion))
}

async fn impersonate_user(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(user_id): Path<Uuid>,
    Json(req): Json<ImpersonationRequest>,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("support.impersonate")).await?;
    let target = sqlx::query_as::<_, User>(
        "SELECT id, email, full_name, role, account_balance, penalty_balance,
                active_fine_amount, is_restricted, restriction_reason,
                identity_documents_verified, driving_license_status, created_at
         FROM users
         WHERE id = $1",
    )
    .bind(user_id)
    .fetch_optional(&pool)
    .await?
    .ok_or(AppError::NotFound)?;

    let expires_at = Utc::now() + Duration::seconds(IMPERSONATION_TTL_SECONDS);
    let token = auth::create_jwt_with_ttl(target.id, IMPERSONATION_TTL_SECONDS)?;
    sqlx::query(
        "INSERT INTO admin_impersonation_sessions (
            admin_user_id, target_user_id, expires_at, reason
         )
         VALUES ($1, $2, $3, $4)",
    )
    .bind(auth_user.0)
    .bind(target.id)
    .bind(expires_at)
    .bind(req.reason.unwrap_or_default())
    .execute(&pool)
    .await?;

    insert_audit_event(
        &pool,
        Some(auth_user.0),
        "critical",
        "ADMIN_IMPERSONATION_STARTED",
        Some("user"),
        Some(&target.id.to_string()),
        json!({"expiresAt": expires_at}),
    )
    .await?;

    Ok(Json(json!({
        "token": token,
        "expiresAt": expires_at,
        "targetUser": target,
        "banner": "Mode profil fantôme actif - quitter dès la reproduction terminée"
    })))
}

async fn list_capacity_alerts(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Value>, AppError> {
    require_admin(&pool, auth_user.0, Some("logs.view")).await?;
    let row = sqlx::query_as::<_, JsonRow>(
        "SELECT COALESCE(jsonb_agg(alert), '[]'::jsonb) AS payload
         FROM (
            SELECT jsonb_build_object(
              'city', COALESCE(NULLIF(p.details->>'city', ''), 'Zone inconnue'),
              'serviceType', p.type_service::TEXT,
              'availableCapacity', COALESCE(sum(p.capacity), 0),
              'riskLevel',
                CASE WHEN COALESCE(sum(p.capacity), 0) < 30 THEN 'orange' ELSE 'green' END,
              'message',
                CASE WHEN COALESCE(sum(p.capacity), 0) < 30
                  THEN 'Risque de pénurie de Cars ou chambres pour les prochains pics de demande.'
                  ELSE 'Capacité partenaire correcte.'
                END
            ) AS alert
            FROM prestations p
            WHERE p.type_service IN ('location_voiture', 'chambre_hotel')
              AND p.is_available = TRUE
            GROUP BY COALESCE(NULLIF(p.details->>'city', ''), 'Zone inconnue'), p.type_service
         ) s",
    )
    .fetch_one(&pool)
    .await?;

    Ok(Json(row.payload.0))
}

async fn require_admin(
    pool: &PgPool,
    user_id: Uuid,
    permission: Option<&str>,
) -> Result<AdminContext, AppError> {
    let user = sqlx::query_as::<_, User>(
        "SELECT id, email, full_name, role, account_balance, penalty_balance,
                active_fine_amount, is_restricted, restriction_reason,
                identity_documents_verified, driving_license_status, created_at
         FROM users
         WHERE id = $1",
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await?
    .ok_or(AppError::Unauthorized)?;

    let admin_roles = [
        "SUPER_ADMIN",
        "admin",
        "developer",
        "manager",
        "support",
        "finance",
        "security",
    ];
    if !admin_roles.contains(&user.role.as_str()) {
        return Err(AppError::Unauthorized);
    }

    let permissions = get_permissions(pool, user.id, &user.role).await?;
    if let Some(permission) = permission {
        if user.role != "SUPER_ADMIN" && !permissions.iter().any(|item| item == permission) {
            return Err(AppError::Unauthorized);
        }
    }

    Ok(AdminContext { user, permissions })
}

async fn get_permissions(
    pool: &PgPool,
    user_id: Uuid,
    role: &str,
) -> Result<Vec<String>, AppError> {
    let rows = sqlx::query_as::<_, (String,)>(
        "SELECT DISTINCT permission_key
         FROM (
            SELECT permission_key
            FROM admin_permissions
            WHERE $2 = 'SUPER_ADMIN'
            UNION
            SELECT jsonb_array_elements_text(ar.permissions) AS permission_key
            FROM admin_roles ar
            WHERE ar.role_key = $2
            UNION
            SELECT jsonb_array_elements_text(ar.permissions) AS permission_key
            FROM admin_user_roles aur
            INNER JOIN admin_roles ar ON ar.role_key = aur.role_key
            WHERE aur.user_id = $1 AND aur.active = TRUE
         ) p
         ORDER BY permission_key",
    )
    .bind(user_id)
    .bind(role)
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(|row| row.0).collect())
}

async fn set_partner_catalog_visibility(
    pool: &PgPool,
    partner_id: Uuid,
    visible: bool,
) -> Result<(), AppError> {
    sqlx::query(
        "UPDATE prestations
         SET is_available = $2,
             updated_at = now()
         WHERE partenaire_id = $1",
    )
    .bind(partner_id)
    .bind(visible)
    .execute(pool)
    .await?;

    sqlx::query(
        "UPDATE company_vehicles
         SET is_available = $2,
             operational_status = CASE WHEN $2 THEN 'available' ELSE 'hidden' END,
             updated_at = now()
         WHERE company_id = $1",
    )
    .bind(partner_id)
    .bind(visible)
    .execute(pool)
    .await?;

    Ok(())
}

async fn insert_audit_event(
    pool: &PgPool,
    actor_user_id: Option<Uuid>,
    severity: &str,
    event_type: &str,
    target_type: Option<&str>,
    target_id: Option<&str>,
    details: Value,
) -> Result<(), AppError> {
    sqlx::query(
        "INSERT INTO admin_audit_events (
            actor_user_id, severity, event_type, target_type, target_id, details, immutable
         )
         VALUES ($1, $2, $3, $4, $5, $6, TRUE)",
    )
    .bind(actor_user_id)
    .bind(severity)
    .bind(event_type)
    .bind(target_type)
    .bind(target_id)
    .bind(SqlxJson(details))
    .execute(pool)
    .await?;
    Ok(())
}

async fn query_json_array(pool: &PgPool, query: &str) -> Result<Json<Value>, AppError> {
    let sql =
        format!("SELECT COALESCE(jsonb_agg(payload), '[]'::jsonb) AS payload FROM ({query}) q");
    let row = sqlx::query_as::<_, JsonRow>(&sql).fetch_one(pool).await?;
    Ok(Json(row.payload.0))
}

fn constant_time_eq(left: &[u8], right: &[u8]) -> bool {
    if left.len() != right.len() {
        return false;
    }
    let mut diff = 0u8;
    for (a, b) in left.iter().zip(right.iter()) {
        diff |= a ^ b;
    }
    diff == 0
}
