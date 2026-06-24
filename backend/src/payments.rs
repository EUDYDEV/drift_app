use axum::{extract::State, http::StatusCode, routing::post, Json, Router};
use chrono::{NaiveDate, Utc};
use serde_json::{json, Value};
use sqlx::{types::Json as SqlxJson, PgPool, Postgres, Transaction};
use uuid::Uuid;

use crate::{
    auth,
    error::AppError,
    models::{
        CheckoutPackItemRequest, CheckoutPaymentRequest, Payment, PaymentCheckoutResponse,
        Reservation,
    },
};

pub fn payment_routes() -> Router<PgPool> {
    Router::new().route("/checkout", post(checkout))
}

#[derive(Debug, Clone, Copy)]
enum GatewayStatus {
    Pending,
    Success,
    Failed,
}

impl GatewayStatus {
    fn as_str(self) -> &'static str {
        match self {
            Self::Pending => "PENDING",
            Self::Success => "SUCCESS",
            Self::Failed => "FAILED",
        }
    }

    fn http_status(self) -> StatusCode {
        match self {
            Self::Pending => StatusCode::ACCEPTED,
            Self::Success => StatusCode::CREATED,
            Self::Failed => StatusCode::PAYMENT_REQUIRED,
        }
    }
}

#[derive(Debug)]
struct GatewayResult {
    status: GatewayStatus,
    provider: String,
    provider_reference: String,
    payment_method_token: Option<String>,
    payment_method_last4: Option<String>,
    failure_reason: Option<String>,
    provider_payload: Value,
}

#[derive(Debug, sqlx::FromRow)]
struct PaymentRow {
    id: Uuid,
    user_id: Uuid,
    reservation_id: Option<Uuid>,
    reservation_ids: SqlxJson<Vec<Uuid>>,
    status: String,
    amount: f64,
    currency: String,
    payment_method_code: String,
    payment_method_label: Option<String>,
    payment_method_token: Option<String>,
    payment_method_last4: Option<String>,
    payment_provider: String,
    provider_reference: String,
    failure_reason: Option<String>,
    created_at: chrono::DateTime<Utc>,
    updated_at: chrono::DateTime<Utc>,
}

impl From<PaymentRow> for Payment {
    fn from(row: PaymentRow) -> Self {
        Self {
            id: row.id,
            user_id: row.user_id,
            reservation_id: row.reservation_id,
            reservation_ids: row.reservation_ids.0,
            status: row.status,
            amount: row.amount,
            currency: row.currency,
            payment_method_code: row.payment_method_code,
            payment_method_label: row.payment_method_label,
            payment_method_last4: row.payment_method_last4,
            payment_provider: row.payment_provider,
            provider_reference: row.provider_reference,
            failure_reason: row.failure_reason,
            created_at: row.created_at,
            updated_at: row.updated_at,
            payment_method_token: row.payment_method_token,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct ReservationRow {
    id: Uuid,
    user_id: Uuid,
    hotel_id: Uuid,
    room_id: Uuid,
    capacity: i32,
    price: f64,
    start_date: NaiveDate,
    end_date: NaiveDate,
    created_at: chrono::DateTime<Utc>,
}

impl From<ReservationRow> for Reservation {
    fn from(row: ReservationRow) -> Self {
        Self {
            id: row.id,
            user_id: row.user_id,
            hotel_id: row.hotel_id,
            room_id: row.room_id,
            capacity: row.capacity,
            price: row.price,
            start_date: row.start_date,
            end_date: row.end_date,
            created_at: row.created_at,
        }
    }
}

pub async fn checkout(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<CheckoutPaymentRequest>,
) -> Result<(StatusCode, Json<PaymentCheckoutResponse>), AppError> {
    if req.items.is_empty() {
        return Err(AppError::BadRequest(
            "items must contain at least one pack prestation".to_string(),
        ));
    }

    if req.total_amount <= 0.0 {
        return Err(AppError::BadRequest(
            "totalAmount must be greater than 0".to_string(),
        ));
    }

    let calculated_total: f64 = req.items.iter().map(|item| item.amount.max(0.0)).sum();
    if (calculated_total - req.total_amount).abs() > 1.0 {
        return Err(AppError::BadRequest(format!(
            "The submitted totalAmount ({:.0}) does not match the pack total ({:.0})",
            req.total_amount, calculated_total
        )));
    }

    let currency = req
        .currency
        .clone()
        .unwrap_or_else(|| "XOF".to_string())
        .trim()
        .to_ascii_uppercase();

    let gateway = simulate_gateway_charge(&req)?;
    let mut tx = pool.begin().await?;
    let payment_id =
        insert_pending_payment(&mut tx, auth_user.0, &req, &currency, calculated_total).await?;

    let reservations = if matches!(gateway.status, GatewayStatus::Success) {
        create_pack_reservations(&mut tx, auth_user.0, &req.items).await?
    } else {
        Vec::new()
    };

    let reservation_ids = reservations
        .iter()
        .map(|reservation| reservation.id)
        .collect::<Vec<_>>();
    let primary_reservation_id = reservation_ids.first().copied();

    let payment = finalize_payment(
        &mut tx,
        payment_id,
        primary_reservation_id,
        &reservation_ids,
        &gateway,
    )
    .await?;

    tx.commit().await?;

    let message = match gateway.status {
        GatewayStatus::Success => {
            "Paiement confirme. Votre pack Drift est maintenant securise.".to_string()
        }
        GatewayStatus::Pending => {
            "Paiement initie. La confirmation de l'agregateur est en attente.".to_string()
        }
        GatewayStatus::Failed => gateway
            .failure_reason
            .clone()
            .unwrap_or_else(|| "Le paiement a ete refuse par l'agregateur.".to_string()),
    };

    Ok((
        gateway.status.http_status(),
        Json(PaymentCheckoutResponse {
            payment,
            reservations,
            message,
        }),
    ))
}

fn simulate_gateway_charge(req: &CheckoutPaymentRequest) -> Result<GatewayResult, AppError> {
    let code = normalize_payment_code(&req.payment_method.code);
    let provider = payment_provider_for(&code).to_string();
    let provider_reference = format!("PAY-{}-{}", provider.to_uppercase(), Uuid::new_v4());
    let last4 = payment_last4(&req.payment_method.phone_number, &req.payment_method.email);

    let needs_phone = matches!(code.as_str(), "ORANGE_MONEY" | "MTN_MONEY" | "MOOV_MONEY");
    if needs_phone
        && req
            .payment_method
            .phone_number
            .as_deref()
            .unwrap_or("")
            .trim()
            .is_empty()
    {
        return Err(AppError::BadRequest(
            "phoneNumber is required for Mobile Money checkout".to_string(),
        ));
    }

    let status = if req.total_amount <= 0.0 {
        GatewayStatus::Failed
    } else if req
        .payment_method
        .phone_number
        .as_deref()
        .unwrap_or("")
        .ends_with("9999")
        || req
            .payment_method
            .email
            .as_deref()
            .unwrap_or("")
            .to_ascii_lowercase()
            .contains("+fail")
    {
        GatewayStatus::Failed
    } else if req
        .payment_method
        .phone_number
        .as_deref()
        .unwrap_or("")
        .ends_with("1111")
        || req.total_amount >= 1_500_000.0
    {
        GatewayStatus::Pending
    } else {
        GatewayStatus::Success
    };

    let failure_reason = if matches!(status, GatewayStatus::Failed) {
        Some("Le compte selectionne ne dispose pas du solde requis.".to_string())
    } else {
        None
    };

    let payment_method_token = if matches!(status, GatewayStatus::Success) {
        Some(tokenize_payment_method(&code))
    } else {
        None
    };

    let provider_payload = json!({
        "gateway": provider,
        "channel": code,
        "reference": provider_reference,
        "status": status.as_str(),
        "tokenized": payment_method_token.is_some(),
        "holderName": req.payment_method.holder_name,
        "phoneNumber": req.payment_method.phone_number,
        "email": req.payment_method.email,
    });

    Ok(GatewayResult {
        status,
        provider,
        provider_reference,
        payment_method_token,
        payment_method_last4: last4,
        failure_reason,
        provider_payload,
    })
}

async fn insert_pending_payment(
    tx: &mut Transaction<'_, Postgres>,
    user_id: Uuid,
    req: &CheckoutPaymentRequest,
    currency: &str,
    amount: f64,
) -> Result<Uuid, sqlx::Error> {
    let payload = json!({
        "totalAmount": amount,
        "currency": currency,
        "paymentMethod": {
            "code": normalize_payment_code(&req.payment_method.code),
            "label": req.payment_method.label,
            "phoneNumber": req.payment_method.phone_number,
            "holderName": req.payment_method.holder_name,
            "email": req.payment_method.email,
        },
        "items": req.items.iter().map(serialize_pack_item).collect::<Vec<_>>(),
    });

    sqlx::query_as::<_, (Uuid,)>(
        "INSERT INTO payments (
            user_id, reservation_id, reservation_ids, status, amount, currency,
            payment_method_code, payment_method_label, payment_provider, provider_reference,
            failure_reason, payer_phone_number, payer_email, payer_full_name,
            payment_payload, provider_payload
         ) VALUES (
            $1, NULL, '[]'::jsonb, 'PENDING', $2, $3,
            $4, $5, 'gateway_pending', 'pending',
            NULL, $6, $7, $8,
            $9, '{}'::jsonb
         )
         RETURNING id",
    )
    .bind(user_id)
    .bind(amount)
    .bind(currency)
    .bind(normalize_payment_code(&req.payment_method.code))
    .bind(req.payment_method.label.as_deref())
    .bind(req.payment_method.phone_number.as_deref())
    .bind(req.payment_method.email.as_deref())
    .bind(req.payment_method.holder_name.as_deref())
    .bind(SqlxJson(payload))
    .fetch_one(&mut **tx)
    .await
    .map(|row| row.0)
}

async fn finalize_payment(
    tx: &mut Transaction<'_, Postgres>,
    payment_id: Uuid,
    reservation_id: Option<Uuid>,
    reservation_ids: &[Uuid],
    gateway: &GatewayResult,
) -> Result<Payment, sqlx::Error> {
    let row = sqlx::query_as::<_, PaymentRow>(
        "UPDATE payments
         SET reservation_id = $1,
             reservation_ids = $2,
             status = $3,
             payment_method_token = $4,
             payment_method_last4 = $5,
             payment_provider = $6,
             provider_reference = $7,
             failure_reason = $8,
             provider_payload = $9,
             completed_at = CASE WHEN $3 = 'SUCCESS' THEN now() ELSE completed_at END,
             updated_at = now()
         WHERE id = $10
         RETURNING id, user_id, reservation_id, reservation_ids, status, amount,
                   currency, payment_method_code, payment_method_label,
                   payment_method_token, payment_method_last4, payment_provider,
                   provider_reference, failure_reason, created_at, updated_at",
    )
    .bind(reservation_id)
    .bind(SqlxJson(reservation_ids.to_vec()))
    .bind(gateway.status.as_str())
    .bind(gateway.payment_method_token.as_deref())
    .bind(gateway.payment_method_last4.as_deref())
    .bind(&gateway.provider)
    .bind(&gateway.provider_reference)
    .bind(gateway.failure_reason.as_deref())
    .bind(SqlxJson(gateway.provider_payload.clone()))
    .bind(payment_id)
    .fetch_one(&mut **tx)
    .await?;

    Ok(Payment::from(row))
}

async fn create_pack_reservations(
    tx: &mut Transaction<'_, Postgres>,
    user_id: Uuid,
    items: &[CheckoutPackItemRequest],
) -> Result<Vec<Reservation>, AppError> {
    let mut reservations = Vec::new();

    for item in items {
        if !item.service_type.eq_ignore_ascii_case("chambre_hotel") {
            continue;
        }

        let Some(room_id) = extract_room_id(item) else {
            continue;
        };

        let start_date = extract_reservation_date(item, true).ok_or_else(|| {
            AppError::BadRequest(format!(
                "reservationStart is required for hotel item {}",
                item.cart_item_id
            ))
        })?;
        let end_date = extract_reservation_date(item, false).ok_or_else(|| {
            AppError::BadRequest(format!(
                "reservationEnd is required for hotel item {}",
                item.cart_item_id
            ))
        })?;

        let reservation = sqlx::query_as::<_, ReservationRow>(
            "INSERT INTO reservations (user_id, hotel_id, room_id, capacity, price, start_date, end_date)
             SELECT $1, hotel_id, id, capacity, price, $3, $4
             FROM rooms
             WHERE id = $2
             RETURNING id, user_id, hotel_id, room_id, capacity,
                       price::DOUBLE PRECISION AS price, start_date, end_date, created_at",
        )
        .bind(user_id)
        .bind(room_id)
        .bind(start_date)
        .bind(end_date)
        .fetch_one(&mut **tx)
        .await?;

        reservations.push(Reservation::from(reservation));
    }

    Ok(reservations)
}

fn extract_room_id(item: &CheckoutPackItemRequest) -> Option<Uuid> {
    let metadata = item.metadata.as_ref()?.as_object()?;
    let raw = metadata
        .get("roomId")
        .or_else(|| metadata.get("room_id"))?
        .as_str()?;

    Uuid::parse_str(raw).ok()
}

fn extract_reservation_date(item: &CheckoutPackItemRequest, start: bool) -> Option<NaiveDate> {
    let direct = if start {
        item.reservation_start.map(|value| value.date_naive())
    } else {
        item.reservation_end.map(|value| value.date_naive())
    };

    if direct.is_some() {
        return direct;
    }

    let metadata = item.metadata.as_ref()?.as_object()?;
    let raw = if start {
        metadata
            .get("reservationStart")
            .or_else(|| metadata.get("startDate"))
            .or_else(|| metadata.get("start_date"))
    } else {
        metadata
            .get("reservationEnd")
            .or_else(|| metadata.get("endDate"))
            .or_else(|| metadata.get("end_date"))
    }?;

    NaiveDate::parse_from_str(raw.as_str()?, "%Y-%m-%d").ok()
}

fn serialize_pack_item(item: &CheckoutPackItemRequest) -> Value {
    json!({
        "cartItemId": item.cart_item_id,
        "itemType": item.item_type,
        "serviceType": item.service_type,
        "name": item.name,
        "subtitle": item.subtitle,
        "amount": item.amount,
        "partnerId": item.partner_id,
        "prestationId": item.prestation_id,
        "reservationStart": item.reservation_start,
        "reservationEnd": item.reservation_end,
        "metadata": item.metadata.clone().unwrap_or_else(|| Value::Object(Default::default())),
    })
}

fn normalize_payment_code(raw: &str) -> String {
    match raw.trim().to_ascii_uppercase().as_str() {
        "OM" | "ORANGE" | "ORANGE_MONEY" => "ORANGE_MONEY".to_string(),
        "MTN" | "MTN_MONEY" => "MTN_MONEY".to_string(),
        "MOOV" | "MOOV_MONEY" => "MOOV_MONEY".to_string(),
        "MC" | "MASTERCARD" => "MASTERCARD".to_string(),
        "VISA" => "VISA".to_string(),
        other => other.to_string(),
    }
}

fn payment_provider_for(code: &str) -> &'static str {
    match code {
        "ORANGE_MONEY" => "orange",
        "MTN_MONEY" => "mtn",
        "MOOV_MONEY" => "moov",
        "MASTERCARD" => "mastercard",
        "VISA" => "visa",
        _ => "generic_gateway",
    }
}

fn tokenize_payment_method(code: &str) -> String {
    format!("pm_{}_{}", code.to_ascii_lowercase(), Uuid::new_v4())
}

fn payment_last4(phone_number: &Option<String>, email: &Option<String>) -> Option<String> {
    if let Some(phone_number) = phone_number.as_deref() {
        let digits = phone_number
            .chars()
            .filter(|char| char.is_ascii_digit())
            .collect::<String>();
        if digits.len() >= 4 {
            return Some(digits[digits.len() - 4..].to_string());
        }
    }

    if let Some(email) = email.as_deref() {
        let compact = email
            .chars()
            .filter(|char| char.is_ascii_alphanumeric())
            .collect::<String>();
        if compact.len() >= 4 {
            return Some(compact[compact.len() - 4..].to_string());
        }
    }

    None
}
