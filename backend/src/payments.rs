use axum::{extract::State, http::StatusCode, routing::post, Json, Router};
use chrono::{NaiveDate, Utc};
use serde_json::{json, Value};
use sqlx::{types::Json as SqlxJson, PgPool, Postgres, Transaction};
use std::collections::HashSet;
use uuid::Uuid;

use crate::{
    auth, db,
    error::AppError,
    models::{
        CheckoutPackItemRequest, CheckoutPaymentRequest, PackTicket, Payment,
        PaymentCheckoutResponse, Reservation,
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

#[derive(Debug, Clone)]
struct ServerPricedItem {
    cart_item_id: String,
    item_type: String,
    service_type: String,
    name: String,
    subtitle: Option<String>,
    amount: f64,
    partner_id: Option<Uuid>,
    prestation_id: Option<Uuid>,
    reservation_start: Option<chrono::DateTime<Utc>>,
    reservation_end: Option<chrono::DateTime<Utc>>,
    metadata: Value,
    legacy_room: Option<LockedRoomOrder>,
    ride_id: Option<Uuid>,
}

#[derive(Debug, Clone)]
struct LockedRoomOrder {
    room_id: Uuid,
    hotel_id: Uuid,
    capacity: i32,
    start_date: NaiveDate,
    end_date: NaiveDate,
}

#[derive(Debug, sqlx::FromRow)]
struct LockedPrestationRow {
    id: Uuid,
    partenaire_id: Uuid,
    type_service: String,
    name: String,
    price: f64,
    is_available: bool,
}

#[derive(Debug, sqlx::FromRow)]
struct LockedRoomRow {
    id: Uuid,
    hotel_id: Uuid,
    room_type: String,
    capacity: i32,
    price: f64,
    available: bool,
}

#[derive(Debug, sqlx::FromRow)]
struct LockedRideRow {
    id: Uuid,
    estimated_price: f64,
    final_amount: f64,
    status: String,
    payment_status: String,
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

    let currency = req
        .currency
        .clone()
        .unwrap_or_else(|| "XOF".to_string())
        .trim()
        .to_ascii_uppercase();

    let mut tx = pool.begin().await?;
    let priced_items = resolve_server_prices(&mut tx, auth_user.0, &req.items).await?;
    let server_total = priced_items.iter().map(|item| item.amount).sum::<f64>();

    validate_submitted_prices(&req, &priced_items, server_total)?;

    let gateway = simulate_gateway_charge(&req, server_total)?;
    let payment_id = insert_pending_payment(
        &mut tx,
        auth_user.0,
        &req,
        &priced_items,
        &currency,
        server_total,
    )
    .await?;

    let (reservations, tickets) = if matches!(gateway.status, GatewayStatus::Success) {
        create_business_orders(&mut tx, auth_user.0, &priced_items).await?
    } else {
        (Vec::new(), Vec::new())
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
            tickets,
            message,
        }),
    ))
}

fn simulate_gateway_charge(
    req: &CheckoutPaymentRequest,
    server_total: f64,
) -> Result<GatewayResult, AppError> {
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

    let status = if server_total <= 0.0 {
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
        || server_total >= 1_500_000.0
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
    priced_items: &[ServerPricedItem],
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
        "submittedTotalAmount": req.total_amount,
        "items": priced_items.iter().map(serialize_server_priced_item).collect::<Vec<_>>(),
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

async fn resolve_server_prices(
    tx: &mut Transaction<'_, Postgres>,
    user_id: Uuid,
    items: &[CheckoutPackItemRequest],
) -> Result<Vec<ServerPricedItem>, AppError> {
    let mut priced_items = Vec::with_capacity(items.len());
    let mut cart_item_ids = HashSet::with_capacity(items.len());

    for item in items {
        if item.cart_item_id.trim().is_empty() {
            return Err(AppError::BadRequest("cartItemId is required".to_string()));
        }
        if !cart_item_ids.insert(item.cart_item_id.trim().to_string()) {
            return Err(AppError::BadRequest(format!(
                "Duplicate cartItemId: {}",
                item.cart_item_id
            )));
        }

        if let Some(prestation_id) = item.prestation_id {
            let row = sqlx::query_as::<_, LockedPrestationRow>(
                "SELECT id, partenaire_id, type_service::TEXT AS type_service, name,
                        price::DOUBLE PRECISION AS price, is_available
                 FROM prestations
                 WHERE id = $1
                 FOR UPDATE",
            )
            .bind(prestation_id)
            .fetch_optional(&mut **tx)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(format!(
                    "SECURITY_UNVERIFIED_ITEM: prestation {} does not exist",
                    item.cart_item_id
                ))
            })?;

            if !row.is_available {
                return Err(AppError::Conflict(format!(
                    "The prestation {} is no longer available",
                    row.name
                )));
            }

            if item
                .partner_id
                .is_some_and(|partner_id| partner_id != row.partenaire_id)
            {
                return Err(AppError::BadRequest(format!(
                    "SECURITY_PARTNER_MISMATCH: invalid partner for {}",
                    item.cart_item_id
                )));
            }

            if !item.service_type.eq_ignore_ascii_case(&row.type_service) {
                return Err(AppError::BadRequest(format!(
                    "SECURITY_SERVICE_MISMATCH: expected {} for {}",
                    row.type_service, item.cart_item_id
                )));
            }

            if row.type_service.eq_ignore_ascii_case("chambre_hotel") {
                let start_date = required_reservation_date(item, true)?;
                let end_date = required_reservation_date(item, false)?;
                if end_date <= start_date {
                    return Err(AppError::BadRequest(format!(
                        "Invalid hotel dates for {}",
                        item.cart_item_id
                    )));
                }
                ensure_prestation_dates_available(
                    tx,
                    row.id,
                    item.reservation_start,
                    item.reservation_end,
                )
                .await?;
            }

            let multiplier = pricing_multiplier(item, &row.type_service)?;
            let amount = rounded_money(row.price * multiplier);
            priced_items.push(ServerPricedItem {
                cart_item_id: item.cart_item_id.clone(),
                item_type: item.item_type.clone(),
                service_type: row.type_service,
                name: row.name,
                subtitle: item.subtitle.clone(),
                amount,
                partner_id: Some(row.partenaire_id),
                prestation_id: Some(row.id),
                reservation_start: item.reservation_start,
                reservation_end: item.reservation_end,
                metadata: item
                    .metadata
                    .clone()
                    .unwrap_or_else(|| Value::Object(Default::default())),
                legacy_room: None,
                ride_id: None,
            });
            continue;
        }

        if let Some(room_id) = extract_room_id(item) {
            let start_date = required_reservation_date(item, true)?;
            let end_date = required_reservation_date(item, false)?;
            if end_date <= start_date {
                return Err(AppError::BadRequest(format!(
                    "Invalid hotel dates for {}",
                    item.cart_item_id
                )));
            }

            let row = sqlx::query_as::<_, LockedRoomRow>(
                "SELECT id, hotel_id, room_type, capacity,
                        price::DOUBLE PRECISION AS price, available
                 FROM rooms
                 WHERE id = $1
                 FOR UPDATE",
            )
            .bind(room_id)
            .fetch_optional(&mut **tx)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(format!(
                    "SECURITY_UNVERIFIED_ITEM: room {} does not exist",
                    item.cart_item_id
                ))
            })?;

            if !row.available {
                return Err(AppError::Conflict(format!(
                    "The room {} is currently unavailable",
                    row.room_type
                )));
            }

            ensure_room_dates_available(tx, row.id, start_date, end_date).await?;

            let multiplier = hotel_multiplier(item, start_date, end_date)?;
            let amount = rounded_money(row.price * multiplier);
            priced_items.push(ServerPricedItem {
                cart_item_id: item.cart_item_id.clone(),
                item_type: item.item_type.clone(),
                service_type: "chambre_hotel".to_string(),
                name: row.room_type,
                subtitle: item.subtitle.clone(),
                amount,
                partner_id: None,
                prestation_id: None,
                reservation_start: item.reservation_start,
                reservation_end: item.reservation_end,
                metadata: item
                    .metadata
                    .clone()
                    .unwrap_or_else(|| Value::Object(Default::default())),
                legacy_room: Some(LockedRoomOrder {
                    room_id: row.id,
                    hotel_id: row.hotel_id,
                    capacity: row.capacity,
                    start_date,
                    end_date,
                }),
                ride_id: None,
            });
            continue;
        }

        if let Some(ride_id) = extract_uuid_metadata(item, &["rideId", "ride_id"]) {
            let row = sqlx::query_as::<_, LockedRideRow>(
                "SELECT id,
                        estimated_price::DOUBLE PRECISION AS estimated_price,
                        final_amount::DOUBLE PRECISION AS final_amount,
                        status,
                        payment_status
                 FROM rides
                 WHERE id = $1 AND user_id = $2
                 FOR UPDATE",
            )
            .bind(ride_id)
            .bind(user_id)
            .fetch_optional(&mut **tx)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(format!(
                    "SECURITY_UNVERIFIED_ITEM: ride {} does not exist",
                    item.cart_item_id
                ))
            })?;

            if matches!(row.status.as_str(), "cancelled" | "restricted") {
                return Err(AppError::Conflict(format!(
                    "Ride {} cannot be paid in status {}",
                    row.id, row.status
                )));
            }

            if row.payment_status.eq_ignore_ascii_case("charged") {
                return Err(AppError::Conflict(format!(
                    "Ride {} has already been paid",
                    row.id
                )));
            }

            let amount = rounded_money(row.final_amount.max(row.estimated_price));
            priced_items.push(ServerPricedItem {
                cart_item_id: item.cart_item_id.clone(),
                item_type: item.item_type.clone(),
                service_type: "location_voiture".to_string(),
                name: item.name.clone(),
                subtitle: item.subtitle.clone(),
                amount,
                partner_id: item.partner_id,
                prestation_id: None,
                reservation_start: item.reservation_start,
                reservation_end: item.reservation_end,
                metadata: item
                    .metadata
                    .clone()
                    .unwrap_or_else(|| Value::Object(Default::default())),
                legacy_room: None,
                ride_id: Some(row.id),
            });
            continue;
        }

        return Err(AppError::BadRequest(format!(
            "SECURITY_UNVERIFIED_ITEM: {} must reference a prestation, room or ride",
            item.cart_item_id
        )));
    }

    Ok(priced_items)
}

fn validate_submitted_prices(
    req: &CheckoutPaymentRequest,
    priced_items: &[ServerPricedItem],
    server_total: f64,
) -> Result<(), AppError> {
    for (submitted, server_item) in req.items.iter().zip(priced_items) {
        if (submitted.amount - server_item.amount).abs() > 1.0 {
            return Err(AppError::BadRequest(format!(
                "SECURITY_PRICE_MISMATCH: {} submitted {:.2}, expected {:.2}",
                submitted.cart_item_id, submitted.amount, server_item.amount
            )));
        }
    }

    if (req.total_amount - server_total).abs() > 1.0 {
        return Err(AppError::BadRequest(format!(
            "SECURITY_TOTAL_MISMATCH: submitted {:.2}, expected {:.2}",
            req.total_amount, server_total
        )));
    }

    Ok(())
}

async fn create_business_orders(
    tx: &mut Transaction<'_, Postgres>,
    user_id: Uuid,
    items: &[ServerPricedItem],
) -> Result<(Vec<Reservation>, Vec<PackTicket>), AppError> {
    let mut reservations = Vec::new();
    let mut tickets = Vec::with_capacity(items.len());

    for item in items {
        if let Some(room) = &item.legacy_room {
            let reservation = sqlx::query_as::<_, ReservationRow>(
                "INSERT INTO reservations (
                    user_id, hotel_id, room_id, capacity, price, start_date, end_date
                 ) VALUES ($1, $2, $3, $4, $5, $6, $7)
                 RETURNING id, user_id, hotel_id, room_id, capacity,
                           price::DOUBLE PRECISION AS price, start_date, end_date, created_at",
            )
            .bind(user_id)
            .bind(room.hotel_id)
            .bind(room.room_id)
            .bind(room.capacity)
            .bind(item.amount)
            .bind(room.start_date)
            .bind(room.end_date)
            .fetch_one(&mut **tx)
            .await?;

            reservations.push(Reservation::from(reservation));
        }

        if let Some(ride_id) = item.ride_id {
            let updated = sqlx::query(
                "UPDATE rides
                 SET payment_status = 'charged', updated_at = now()
                 WHERE id = $1
                   AND user_id = $2
                   AND payment_status <> 'charged'",
            )
            .bind(ride_id)
            .bind(user_id)
            .execute(&mut **tx)
            .await?;

            if updated.rows_affected() != 1 {
                return Err(AppError::Conflict(format!(
                    "Ride {ride_id} was paid concurrently"
                )));
            }
        }

        let issued_at = Utc::now();
        let expires_at = item
            .reservation_end
            .unwrap_or_else(|| issued_at + chrono::Duration::days(30));
        let ticket_id = Uuid::new_v4();
        let token = auth::create_pack_ticket_jwt(
            user_id,
            ticket_id,
            item.partner_id,
            item.prestation_id,
            &item.service_type,
            expires_at,
        )?;

        let ticket = db::create_pack_ticket_in_transaction(
            tx,
            user_id,
            ticket_id,
            item.partner_id,
            item.prestation_id,
            &item.cart_item_id,
            &item.service_type,
            &item.name,
            &token,
            issued_at,
            expires_at,
            item.reservation_start,
            item.reservation_end,
        )
        .await?;
        tickets.push(ticket);
    }

    Ok((reservations, tickets))
}

async fn ensure_room_dates_available(
    tx: &mut Transaction<'_, Postgres>,
    room_id: Uuid,
    start_date: NaiveDate,
    end_date: NaiveDate,
) -> Result<(), AppError> {
    let has_overlap = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS (
            SELECT 1
            FROM reservations
            WHERE room_id = $1
              AND start_date < $3
              AND end_date > $2
        )",
    )
    .bind(room_id)
    .bind(start_date)
    .bind(end_date)
    .fetch_one(&mut **tx)
    .await?;

    if has_overlap {
        return Err(AppError::Conflict(
            "This room is already reserved for the selected dates".to_string(),
        ));
    }

    Ok(())
}

async fn ensure_prestation_dates_available(
    tx: &mut Transaction<'_, Postgres>,
    prestation_id: Uuid,
    reservation_start: Option<chrono::DateTime<Utc>>,
    reservation_end: Option<chrono::DateTime<Utc>>,
) -> Result<(), AppError> {
    let start = reservation_start.ok_or_else(|| {
        AppError::BadRequest("reservationStart is required for hotel prestations".to_string())
    })?;
    let end = reservation_end.ok_or_else(|| {
        AppError::BadRequest("reservationEnd is required for hotel prestations".to_string())
    })?;

    let has_overlap = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS (
            SELECT 1
            FROM pack_tickets
            WHERE prestation_id = $1
              AND status = 'issued'
              AND reservation_start < $3
              AND reservation_end > $2
        )",
    )
    .bind(prestation_id)
    .bind(start)
    .bind(end)
    .fetch_one(&mut **tx)
    .await?;

    if has_overlap {
        return Err(AppError::Conflict(
            "This partner room is already reserved for the selected dates".to_string(),
        ));
    }

    Ok(())
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

fn required_reservation_date(
    item: &CheckoutPackItemRequest,
    start: bool,
) -> Result<NaiveDate, AppError> {
    extract_reservation_date(item, start).ok_or_else(|| {
        AppError::BadRequest(format!(
            "{} is required for hotel item {}",
            if start {
                "reservationStart"
            } else {
                "reservationEnd"
            },
            item.cart_item_id
        ))
    })
}

fn pricing_multiplier(item: &CheckoutPackItemRequest, service_type: &str) -> Result<f64, AppError> {
    if service_type.eq_ignore_ascii_case("chambre_hotel") {
        let start_date = required_reservation_date(item, true)?;
        let end_date = required_reservation_date(item, false)?;
        return hotel_multiplier(item, start_date, end_date);
    }

    if service_type.eq_ignore_ascii_case("location_voiture") {
        if let Some(minutes) = metadata_number(
            item,
            &[
                "requestedDurationMinutes",
                "requested_duration_minutes",
                "durationMinutes",
                "duration_minutes",
            ],
        ) {
            if minutes <= 0.0 {
                return Err(AppError::BadRequest(format!(
                    "Invalid transport duration for {}",
                    item.cart_item_id
                )));
            }
            return Ok(minutes / 60.0);
        }

        if let Some(hours) = metadata_number(
            item,
            &["durationHours", "duration_hours", "pricingMultiplier"],
        ) {
            if hours <= 0.0 {
                return Err(AppError::BadRequest(format!(
                    "Invalid transport duration for {}",
                    item.cart_item_id
                )));
            }
            return Ok(hours);
        }
    }

    let quantity = metadata_number(
        item,
        &[
            "quantity",
            "itemQuantity",
            "item_quantity",
            "pricingMultiplier",
        ],
    )
    .unwrap_or(1.0);
    if quantity <= 0.0 || quantity.fract() != 0.0 {
        return Err(AppError::BadRequest(format!(
            "Invalid quantity for {}",
            item.cart_item_id
        )));
    }
    Ok(quantity)
}

fn hotel_multiplier(
    item: &CheckoutPackItemRequest,
    start_date: NaiveDate,
    end_date: NaiveDate,
) -> Result<f64, AppError> {
    let nights = (end_date - start_date).num_days();
    if nights < 1 {
        return Err(AppError::BadRequest(format!(
            "Hotel stay must contain at least one night for {}",
            item.cart_item_id
        )));
    }

    let room_quantity =
        metadata_number(item, &["roomQuantity", "room_quantity", "quantity"]).unwrap_or(1.0);
    if room_quantity <= 0.0 || room_quantity.fract() != 0.0 {
        return Err(AppError::BadRequest(format!(
            "Invalid room quantity for {}",
            item.cart_item_id
        )));
    }

    Ok(nights as f64 * room_quantity)
}

fn metadata_number(item: &CheckoutPackItemRequest, keys: &[&str]) -> Option<f64> {
    let metadata = item.metadata.as_ref()?.as_object()?;
    keys.iter().find_map(|key| {
        let value = metadata.get(*key)?;
        if let Some(number) = value.as_f64() {
            return Some(number);
        }
        value.as_str()?.trim().parse::<f64>().ok()
    })
}

fn extract_uuid_metadata(item: &CheckoutPackItemRequest, keys: &[&str]) -> Option<Uuid> {
    let metadata = item.metadata.as_ref()?.as_object()?;
    keys.iter().find_map(|key| {
        metadata
            .get(*key)
            .and_then(Value::as_str)
            .and_then(|raw| Uuid::parse_str(raw).ok())
    })
}

fn rounded_money(value: f64) -> f64 {
    (value * 100.0).round() / 100.0
}

fn serialize_server_priced_item(item: &ServerPricedItem) -> Value {
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
        "metadata": item.metadata,
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
