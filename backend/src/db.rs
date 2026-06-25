use crate::{
    error::AppError,
    models::{
        AppLocation, CreatePrestationRequest, CreateRideRequest, Driver, GeoPoint, Hotel,
        PackTicket, Partner, PartnerCatalogPrestation, PartnerWifiAccess, Prestation, Reservation,
        Ride, RideSettlementResponse, Room, User, Voyage,
    },
};
use chrono::{NaiveDate, Utc};
use serde_json::Value;
use sqlx::{types::Json, PgPool, Postgres, QueryBuilder, Transaction};
use uuid::Uuid;

const DEFAULT_HOURLY_RATE: f64 = 12_000.0;
const MINI_CAR_HOURLY_RATE: f64 = 45_000.0;
const PAYMENT_FINE_AMOUNT: f64 = 25_000.0;

const RIDE_SELECT: &str = r#"
SELECT
    r.id,
    r.user_id,
    r.driver_id,
    r.origin,
    r.destination,
    r.pickup_location,
    r.destination_location,
    r.ride_type,
    r.schedule_type,
    r.scheduled_start,
    r.group_context,
    r.passenger_count,
    r.requested_duration_minutes,
    r.vehicle_type,
    r.seat_capacity,
    r.estimated_price,
    r.hourly_rate,
    r.estimated_time_text,
    r.status,
    r.overtime_minutes,
    r.overtime_amount,
    r.final_amount,
    r.payment_status,
    r.penalty_amount,
    r.restriction_reason,
    r.auto_charge_attempted_at,
    r.created_at,
    r.started_at,
    r.completed_at,
    r.updated_at,
    d.name AS driver_name,
    d.phone_number AS driver_phone_number,
    d.rating AS driver_rating,
    d.review_count AS driver_review_count,
    d.vehicle_type AS driver_vehicle_type,
    d.price::DOUBLE PRECISION AS driver_price,
    d.capacity AS driver_capacity,
    d.license_plate AS driver_license_plate,
    d.vehicle_color AS driver_vehicle_color,
    d.status AS driver_status,
    d.current_location AS driver_current_location,
    d.eta AS driver_eta,
    d.created_at AS driver_created_at
FROM rides r
LEFT JOIN drivers d ON d.id = r.driver_id
"#;

#[derive(Debug, sqlx::FromRow)]
struct DriverRow {
    id: Uuid,
    name: String,
    phone_number: String,
    rating: f64,
    review_count: i32,
    vehicle_type: String,
    price: f64,
    capacity: i32,
    license_plate: String,
    vehicle_color: String,
    status: String,
    current_location: Json<AppLocation>,
    eta: i32,
    created_at: chrono::DateTime<Utc>,
}

impl From<DriverRow> for Driver {
    fn from(row: DriverRow) -> Self {
        Self {
            id: row.id,
            name: row.name,
            phone_number: row.phone_number,
            rating: row.rating,
            review_count: row.review_count,
            vehicle_type: row.vehicle_type,
            price: row.price,
            capacity: row.capacity,
            license_plate: row.license_plate,
            vehicle_color: row.vehicle_color,
            status: row.status,
            current_location: row.current_location.0,
            eta: row.eta,
            created_at: row.created_at,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct HotelRow {
    id: Uuid,
    name: String,
    city: String,
    address: String,
    description: String,
    rating: f64,
    review_count: i32,
    price_per_night: f64,
    capacity: i32,
    latitude: f64,
    longitude: f64,
    amenities: Json<Vec<String>>,
    image_urls: Json<Vec<String>>,
    video_360_urls: Json<Vec<String>>,
    is_featured: bool,
    r#type: String,
    wifi_ssid: Option<String>,
    wifi_password_encrypted: Option<String>,
    created_at: chrono::DateTime<Utc>,
}

impl From<HotelRow> for Hotel {
    fn from(row: HotelRow) -> Self {
        Self {
            id: row.id,
            name: row.name,
            city: row.city,
            address: row.address,
            description: row.description,
            rating: row.rating,
            review_count: row.review_count,
            price_per_night: row.price_per_night,
            capacity: row.capacity,
            latitude: row.latitude,
            longitude: row.longitude,
            amenities: row.amenities.0,
            image_urls: row.image_urls.0,
            video_360_urls: row.video_360_urls.0,
            is_featured: row.is_featured,
            r#type: row.r#type,
            wifi_ssid: row.wifi_ssid,
            wifi_password_encrypted: row.wifi_password_encrypted,
            created_at: row.created_at,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct RoomRow {
    id: Uuid,
    hotel_id: Uuid,
    room_type: String,
    capacity: i32,
    price: f64,
    amenities: Json<Vec<String>>,
    available: bool,
    image_urls: Json<Vec<String>>,
    video_360_urls: Json<Vec<String>>,
    created_at: chrono::DateTime<Utc>,
}

impl From<RoomRow> for Room {
    fn from(row: RoomRow) -> Self {
        Self {
            id: row.id,
            hotel_id: row.hotel_id,
            room_type: row.room_type,
            capacity: row.capacity,
            price: row.price,
            amenities: row.amenities.0,
            available: row.available,
            image_urls: row.image_urls.0,
            video_360_urls: row.video_360_urls.0,
            created_at: row.created_at,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct PartnerRow {
    id: Uuid,
    nom_entreprise: String,
    registre_commerce: String,
    telephone: String,
    adresse_gps: Json<GeoPoint>,
    latitude: f64,
    longitude: f64,
    type_partenaire: String,
    is_boosted: bool,
    wifi_ssid: Option<String>,
    wifi_password_encrypted: Option<String>,
    password_hash: String,
    created_at: chrono::DateTime<Utc>,
    updated_at: chrono::DateTime<Utc>,
}

impl From<PartnerRow> for Partner {
    fn from(row: PartnerRow) -> Self {
        Self {
            id: row.id,
            nom_entreprise: row.nom_entreprise,
            registre_commerce: row.registre_commerce,
            telephone: row.telephone,
            adresse_gps: row.adresse_gps.0,
            latitude: row.latitude,
            longitude: row.longitude,
            type_partenaire: row.type_partenaire,
            is_boosted: row.is_boosted,
            wifi_ssid: row.wifi_ssid,
            wifi_password_encrypted: row.wifi_password_encrypted,
            password_hash: row.password_hash,
            created_at: row.created_at,
            updated_at: row.updated_at,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct PrestationRow {
    id: Uuid,
    partenaire_id: Uuid,
    type_service: String,
    name: String,
    price: f64,
    cuisine_category: Option<String>,
    capacity: Option<i32>,
    is_available: bool,
    media_urls: Json<Vec<String>>,
    details: Json<Value>,
    created_at: chrono::DateTime<Utc>,
    updated_at: chrono::DateTime<Utc>,
}

impl From<PrestationRow> for Prestation {
    fn from(row: PrestationRow) -> Self {
        Self {
            id: row.id,
            partenaire_id: row.partenaire_id,
            type_service: row.type_service,
            name: row.name,
            price: row.price,
            cuisine_category: row.cuisine_category,
            capacity: row.capacity,
            is_available: row.is_available,
            media_urls: row.media_urls.0,
            details: row.details.0,
            created_at: row.created_at,
            updated_at: row.updated_at,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct PartnerCatalogPrestationRow {
    id: Uuid,
    partner_id: Uuid,
    partner_name: String,
    partner_type: String,
    partner_is_boosted: bool,
    partner_address_gps: Json<GeoPoint>,
    type_service: String,
    name: String,
    price: f64,
    cuisine_category: Option<String>,
    capacity: Option<i32>,
    is_available: bool,
    media_urls: Json<Vec<String>>,
    details: Json<Value>,
}

impl From<PartnerCatalogPrestationRow> for PartnerCatalogPrestation {
    fn from(row: PartnerCatalogPrestationRow) -> Self {
        Self {
            id: row.id,
            partner_id: row.partner_id,
            partner_name: row.partner_name,
            partner_type: row.partner_type,
            partner_is_boosted: row.partner_is_boosted,
            partner_address_gps: row.partner_address_gps.0,
            type_service: row.type_service,
            name: row.name,
            price: row.price,
            cuisine_category: row.cuisine_category,
            capacity: row.capacity,
            is_available: row.is_available,
            media_urls: row.media_urls.0,
            details: row.details.0,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct PackTicketRow {
    ticket_id: Uuid,
    cart_item_id: String,
    prestation_id: Option<Uuid>,
    partner_id: Option<Uuid>,
    service_type: String,
    name: String,
    token: String,
    issued_at: chrono::DateTime<Utc>,
    expires_at: chrono::DateTime<Utc>,
    reservation_start: Option<chrono::DateTime<Utc>>,
    reservation_end: Option<chrono::DateTime<Utc>>,
    wifi_ssid: Option<String>,
    wifi_password_encrypted: Option<String>,
    partner_address_gps: Option<Json<GeoPoint>>,
}

impl From<PackTicketRow> for PackTicket {
    fn from(row: PackTicketRow) -> Self {
        let wifi_access = match (
            row.wifi_ssid,
            row.wifi_password_encrypted,
            row.partner_address_gps,
        ) {
            (Some(ssid), Some(password_encrypted), Some(partner_address_gps)) => {
                Some(PartnerWifiAccess {
                    ssid,
                    password_encrypted,
                    latitude: partner_address_gps.0.latitude,
                    longitude: partner_address_gps.0.longitude,
                })
            }
            _ => None,
        };

        Self {
            ticket_id: row.ticket_id,
            cart_item_id: row.cart_item_id,
            prestation_id: row.prestation_id,
            partner_id: row.partner_id,
            service_type: row.service_type,
            name: row.name,
            token: row.token,
            issued_at: row.issued_at,
            expires_at: row.expires_at,
            reservation_start: row.reservation_start,
            reservation_end: row.reservation_end,
            wifi_access,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct RideRow {
    id: Uuid,
    user_id: Uuid,
    driver_id: Option<Uuid>,
    origin: String,
    destination: String,
    pickup_location: Json<AppLocation>,
    destination_location: Json<AppLocation>,
    ride_type: String,
    schedule_type: String,
    scheduled_start: Option<chrono::DateTime<Utc>>,
    group_context: String,
    passenger_count: i32,
    requested_duration_minutes: i32,
    vehicle_type: String,
    seat_capacity: i32,
    estimated_price: f64,
    hourly_rate: f64,
    estimated_time_text: String,
    status: String,
    overtime_minutes: i32,
    overtime_amount: f64,
    final_amount: f64,
    payment_status: String,
    penalty_amount: f64,
    restriction_reason: Option<String>,
    auto_charge_attempted_at: Option<chrono::DateTime<Utc>>,
    created_at: chrono::DateTime<Utc>,
    started_at: Option<chrono::DateTime<Utc>>,
    completed_at: Option<chrono::DateTime<Utc>>,
    updated_at: chrono::DateTime<Utc>,
    driver_name: Option<String>,
    driver_phone_number: Option<String>,
    driver_rating: Option<f64>,
    driver_review_count: Option<i32>,
    driver_vehicle_type: Option<String>,
    driver_price: Option<f64>,
    driver_capacity: Option<i32>,
    driver_license_plate: Option<String>,
    driver_vehicle_color: Option<String>,
    driver_status: Option<String>,
    driver_current_location: Option<Json<AppLocation>>,
    driver_eta: Option<i32>,
    driver_created_at: Option<chrono::DateTime<Utc>>,
}

impl RideRow {
    fn build_driver(&self) -> Option<Driver> {
        let driver_id = self.driver_id?;
        Some(Driver {
            id: driver_id,
            name: self
                .driver_name
                .clone()
                .unwrap_or_else(|| "Chauffeur Drift".to_string()),
            phone_number: self.driver_phone_number.clone().unwrap_or_default(),
            rating: self.driver_rating.unwrap_or(0.0),
            review_count: self.driver_review_count.unwrap_or(0),
            vehicle_type: self
                .driver_vehicle_type
                .clone()
                .unwrap_or_else(|| "comfort".to_string()),
            price: self.driver_price.unwrap_or(0.0),
            capacity: self.driver_capacity.unwrap_or(4),
            license_plate: self.driver_license_plate.clone().unwrap_or_default(),
            vehicle_color: self.driver_vehicle_color.clone().unwrap_or_default(),
            status: self
                .driver_status
                .clone()
                .unwrap_or_else(|| "offline".to_string()),
            current_location: self
                .driver_current_location
                .as_ref()
                .map(|location| location.0.clone())
                .unwrap_or_else(|| default_location("Position inconnue")),
            eta: self.driver_eta.unwrap_or(0),
            created_at: self.driver_created_at.unwrap_or_else(Utc::now),
        })
    }
}

impl From<RideRow> for Ride {
    fn from(row: RideRow) -> Self {
        let driver = row.build_driver();
        Self {
            id: row.id,
            user_id: row.user_id,
            driver_id: row.driver_id,
            driver,
            origin: row.origin,
            destination: row.destination,
            pickup_location: row.pickup_location.0,
            destination_location: row.destination_location.0,
            ride_type: row.ride_type,
            schedule_type: row.schedule_type,
            scheduled_start: row.scheduled_start,
            group_context: row.group_context,
            passenger_count: row.passenger_count,
            requested_duration_minutes: row.requested_duration_minutes,
            vehicle_type: row.vehicle_type,
            seat_capacity: row.seat_capacity,
            estimated_price: row.estimated_price,
            hourly_rate: row.hourly_rate,
            estimated_time_text: row.estimated_time_text,
            status: row.status,
            overtime_minutes: row.overtime_minutes,
            overtime_amount: row.overtime_amount,
            final_amount: row.final_amount,
            payment_status: row.payment_status,
            penalty_amount: row.penalty_amount,
            restriction_reason: row.restriction_reason,
            auto_charge_attempted_at: row.auto_charge_attempted_at,
            created_at: row.created_at,
            started_at: row.started_at,
            completed_at: row.completed_at,
            updated_at: row.updated_at,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
struct RideRuntimeRow {
    created_at: chrono::DateTime<Utc>,
    scheduled_start: Option<chrono::DateTime<Utc>>,
    started_at: Option<chrono::DateTime<Utc>>,
    requested_duration_minutes: i32,
    status: String,
    estimated_price: f64,
    hourly_rate: f64,
    penalty_amount: f64,
}

#[derive(Debug, sqlx::FromRow)]
struct RideFinancialRow {
    driver_id: Option<Uuid>,
    estimated_price: f64,
    overtime_amount: f64,
    penalty_amount: f64,
}

#[derive(Debug, sqlx::FromRow)]
struct UserBalanceRow {
    account_balance: f64,
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

#[derive(Debug)]
struct PricingTerms {
    ride_type: String,
    schedule_type: String,
    group_context: String,
    vehicle_type: String,
    seat_capacity: i32,
    hourly_rate: f64,
    estimated_price: f64,
}

fn default_location(address: &str) -> AppLocation {
    AppLocation {
        latitude: 0.0,
        longitude: 0.0,
        address: address.to_string(),
        city: Some("Abidjan".to_string()),
        country: Some("Cote d'Ivoire".to_string()),
    }
}

fn normalize_schedule_type(value: &str) -> String {
    if value.eq_ignore_ascii_case("scheduled") {
        "scheduled".to_string()
    } else {
        "immediate".to_string()
    }
}

fn normalize_group_context(value: &str) -> String {
    match value.trim().to_ascii_lowercase().as_str() {
        "couple" => "couple".to_string(),
        "family" => "family".to_string(),
        "group" => "group".to_string(),
        "solo" | "business" | "solo_business" | "solobusiness" | "solo/affaires" => {
            "soloBusiness".to_string()
        }
        _ => "soloBusiness".to_string(),
    }
}

fn normalize_ride_type(value: &str) -> String {
    match value.trim() {
        "withoutDriver" => "withoutDriver".to_string(),
        _ => "withDriver".to_string(),
    }
}

fn normalize_vehicle_type(value: &str) -> String {
    match value.trim().to_ascii_lowercase().as_str() {
        "economy" => "economy".to_string(),
        "premium" => "premium".to_string(),
        "mini-car" | "minicar" | "mini_car" => "mini-car".to_string(),
        _ => "comfort".to_string(),
    }
}

fn default_seat_capacity(vehicle_type: &str) -> i32 {
    match vehicle_type {
        "mini-car" => 30,
        _ => 4,
    }
}

fn base_hourly_rate(vehicle_type: &str) -> f64 {
    match vehicle_type {
        "economy" => DEFAULT_HOURLY_RATE,
        "premium" => 25_000.0,
        "mini-car" => MINI_CAR_HOURLY_RATE,
        _ => 18_000.0,
    }
}

fn group_multiplier(group_context: &str) -> f64 {
    match group_context {
        "couple" => 1.10,
        "family" => 1.25,
        "group" => 1.45,
        _ => 1.0,
    }
}

fn format_duration_label(total_minutes: i32) -> String {
    let minutes = total_minutes.max(0);
    if minutes < 60 {
        return format!("{minutes} min");
    }

    let hours = minutes / 60;
    let remainder = minutes % 60;
    if remainder == 0 {
        format!("{hours}h")
    } else {
        format!("{hours}h {remainder}min")
    }
}

fn build_pricing_terms(request: &CreateRideRequest) -> PricingTerms {
    let passenger_count = request.passenger_count.max(1);
    let group_context = normalize_group_context(&request.group_context);
    let force_mini_car = group_context == "group" && passenger_count >= 10;

    let vehicle_type = if force_mini_car {
        "mini-car".to_string()
    } else {
        normalize_vehicle_type(&request.vehicle_type)
    };

    let seat_capacity = if force_mini_car {
        30
    } else {
        request
            .seat_capacity
            .filter(|value| *value > 0)
            .unwrap_or_else(|| default_seat_capacity(&vehicle_type))
    };

    let quoted_price = request.quoted_price.max(0.0);
    let base_rate = base_hourly_rate(&vehicle_type);
    let multiplier = if force_mini_car {
        1.0
    } else {
        group_multiplier(&group_context)
    };

    let hourly_rate = if force_mini_car {
        MINI_CAR_HOURLY_RATE.max(quoted_price)
    } else {
        quoted_price.max(base_rate * multiplier)
    };

    let requested_duration_minutes = request.requested_duration_minutes.max(30);
    let estimated_price = ((requested_duration_minutes as f64 / 60.0) * hourly_rate).ceil();

    PricingTerms {
        ride_type: normalize_ride_type(&request.ride_type),
        schedule_type: normalize_schedule_type(&request.schedule_type),
        group_context,
        vehicle_type,
        seat_capacity,
        hourly_rate,
        estimated_price,
    }
}

async fn fetch_ride_by_id(
    pool: &PgPool,
    ride_id: Uuid,
    user_id: Uuid,
) -> Result<Option<Ride>, sqlx::Error> {
    let query = format!("{RIDE_SELECT} WHERE r.id = $1 AND r.user_id = $2");
    let row = sqlx::query_as::<_, RideRow>(&query)
        .bind(ride_id)
        .bind(user_id)
        .fetch_optional(pool)
        .await?;

    Ok(row.map(Ride::from))
}

async fn fetch_rides_for_user(pool: &PgPool, user_id: Uuid) -> Result<Vec<Ride>, sqlx::Error> {
    let query = format!("{RIDE_SELECT} WHERE r.user_id = $1 ORDER BY r.created_at DESC");
    let rows = sqlx::query_as::<_, RideRow>(&query)
        .bind(user_id)
        .fetch_all(pool)
        .await?;

    Ok(rows.into_iter().map(Ride::from).collect())
}

async fn sync_active_rides_for_user(pool: &PgPool, user_id: Uuid) -> Result<(), sqlx::Error> {
    let ride_ids = sqlx::query_as::<_, (Uuid,)>(
        "SELECT id
         FROM rides
         WHERE user_id = $1
           AND status IN ('requested', 'accepted', 'scheduled', 'inProgress', 'overtime')",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await?;

    for (ride_id,) in ride_ids {
        sync_ride_runtime(pool, ride_id, user_id).await?;
    }

    Ok(())
}

async fn sync_ride_runtime(pool: &PgPool, ride_id: Uuid, user_id: Uuid) -> Result<(), sqlx::Error> {
    let mut tx = pool.begin().await?;
    sync_ride_runtime_tx(&mut tx, ride_id, user_id).await?;
    tx.commit().await?;
    Ok(())
}

async fn sync_ride_runtime_tx(
    tx: &mut Transaction<'_, Postgres>,
    ride_id: Uuid,
    user_id: Uuid,
) -> Result<(), sqlx::Error> {
    let runtime = sqlx::query_as::<_, RideRuntimeRow>(
        "SELECT created_at, scheduled_start, started_at, requested_duration_minutes,
                status, estimated_price, hourly_rate, penalty_amount
         FROM rides
         WHERE id = $1 AND user_id = $2
         FOR UPDATE",
    )
    .bind(ride_id)
    .bind(user_id)
    .fetch_optional(&mut **tx)
    .await?;

    let Some(runtime) = runtime else {
        return Ok(());
    };

    if matches!(
        runtime.status.as_str(),
        "completed" | "cancelled" | "restricted"
    ) {
        return Ok(());
    }

    let requested_duration_minutes = runtime.requested_duration_minutes.max(30);
    let effective_start = runtime
        .started_at
        .or(runtime.scheduled_start)
        .unwrap_or(runtime.created_at);
    let now = Utc::now();

    let mut next_status = runtime.status.clone();
    let mut overtime_minutes = 0;
    let mut overtime_amount = 0.0;

    if runtime.status != "requested" {
        if effective_start > now {
            next_status = "scheduled".to_string();
        } else {
            let elapsed_minutes = (now - effective_start).num_minutes().max(0) as i32;

            if elapsed_minutes > 0 && matches!(runtime.status.as_str(), "accepted" | "scheduled") {
                next_status = "inProgress".to_string();
            }

            overtime_minutes = (elapsed_minutes - requested_duration_minutes).max(0);
            overtime_amount =
                ((overtime_minutes as f64 / 60.0) * runtime.hourly_rate.max(0.0)).ceil();

            if overtime_minutes > 0 {
                next_status = "overtime".to_string();
            }
        }
    }

    let final_amount = runtime.estimated_price + overtime_amount + runtime.penalty_amount;

    sqlx::query(
        "UPDATE rides
         SET status = $1,
             overtime_minutes = $2,
             overtime_amount = $3,
             final_amount = $4,
             updated_at = now()
         WHERE id = $5 AND user_id = $6",
    )
    .bind(next_status)
    .bind(overtime_minutes)
    .bind(overtime_amount)
    .bind(final_amount)
    .bind(ride_id)
    .bind(user_id)
    .execute(&mut **tx)
    .await?;

    Ok(())
}

// ========== USER DAO ==========
pub async fn create_user(
    pool: &PgPool,
    email: &str,
    full_name: &str,
    password_hash: &str,
) -> Result<User, sqlx::Error> {
    sqlx::query_as::<_, User>(
        "INSERT INTO users (email, full_name, password_hash)
         VALUES ($1, $2, $3)
         RETURNING id, email, full_name, account_balance, penalty_balance, active_fine_amount,
                   is_restricted, restriction_reason, created_at",
    )
    .bind(email)
    .bind(full_name)
    .bind(password_hash)
    .fetch_one(pool)
    .await
}

pub async fn get_user_by_email(
    pool: &PgPool,
    email: &str,
) -> Result<Option<(Uuid, String)>, sqlx::Error> {
    sqlx::query_as::<_, (Uuid, String)>("SELECT id, password_hash FROM users WHERE email = $1")
        .bind(email)
        .fetch_optional(pool)
        .await
}

pub async fn get_user_by_id(pool: &PgPool, id: Uuid) -> Result<Option<User>, sqlx::Error> {
    sqlx::query_as::<_, User>(
        "SELECT id, email, full_name, account_balance, penalty_balance, active_fine_amount,
                is_restricted, restriction_reason, created_at
         FROM users
         WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
}

// ========== PARTNER DAO ==========
pub async fn create_partner(
    pool: &PgPool,
    nom_entreprise: &str,
    registre_commerce: &str,
    telephone: &str,
    adresse_gps: &GeoPoint,
    type_partenaire: &str,
    is_boosted: bool,
    wifi_ssid: Option<&str>,
    wifi_password_encrypted: Option<&str>,
    password_hash: &str,
) -> Result<Partner, sqlx::Error> {
    let row = sqlx::query_as::<_, PartnerRow>(
        "INSERT INTO partenaires (
            nom_entreprise, registre_commerce, telephone, adresse_gps, latitude, longitude,
            type_partenaire, is_boosted, wifi_ssid, wifi_password_encrypted, password_hash
         ) VALUES (
            $1, $2, $3, $4, $5, $6,
            $7::partner_type_enum, $8, $9, $10, $11
         )
         RETURNING id, nom_entreprise, registre_commerce, telephone, adresse_gps, latitude,
                   longitude,
                   type_partenaire::TEXT AS type_partenaire, is_boosted, wifi_ssid,
                   wifi_password_encrypted, password_hash, created_at, updated_at",
    )
    .bind(nom_entreprise)
    .bind(registre_commerce)
    .bind(telephone)
    .bind(Json(adresse_gps.clone()))
    .bind(adresse_gps.latitude)
    .bind(adresse_gps.longitude)
    .bind(type_partenaire)
    .bind(is_boosted)
    .bind(wifi_ssid)
    .bind(wifi_password_encrypted)
    .bind(password_hash)
    .fetch_one(pool)
    .await?;

    Ok(Partner::from(row))
}

pub async fn get_partner_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Partner>, sqlx::Error> {
    let row = sqlx::query_as::<_, PartnerRow>(
        "SELECT id, nom_entreprise, registre_commerce, telephone, adresse_gps, latitude,
                longitude,
                type_partenaire::TEXT AS type_partenaire, is_boosted, wifi_ssid,
                wifi_password_encrypted, password_hash, created_at, updated_at
         FROM partenaires
         WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(Partner::from))
}

pub async fn get_partner_by_telephone(
    pool: &PgPool,
    telephone: &str,
) -> Result<Option<Partner>, sqlx::Error> {
    let row = sqlx::query_as::<_, PartnerRow>(
        "SELECT id, nom_entreprise, registre_commerce, telephone, adresse_gps, latitude,
                longitude,
                type_partenaire::TEXT AS type_partenaire, is_boosted, wifi_ssid,
                wifi_password_encrypted, password_hash, created_at, updated_at
         FROM partenaires
         WHERE telephone = $1",
    )
    .bind(telephone)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(Partner::from))
}

pub async fn get_partner_by_registre_commerce(
    pool: &PgPool,
    registre_commerce: &str,
) -> Result<Option<Partner>, sqlx::Error> {
    let row = sqlx::query_as::<_, PartnerRow>(
        "SELECT id, nom_entreprise, registre_commerce, telephone, adresse_gps, latitude,
                longitude,
                type_partenaire::TEXT AS type_partenaire, is_boosted, wifi_ssid,
                wifi_password_encrypted, password_hash, created_at, updated_at
         FROM partenaires
         WHERE registre_commerce = $1",
    )
    .bind(registre_commerce)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(Partner::from))
}

pub async fn get_partner_auth_by_telephone(
    pool: &PgPool,
    telephone: &str,
) -> Result<Option<(Uuid, String)>, sqlx::Error> {
    sqlx::query_as::<_, (Uuid, String)>(
        "SELECT id, password_hash
         FROM partenaires
         WHERE telephone = $1",
    )
    .bind(telephone)
    .fetch_optional(pool)
    .await
}

// ========== PRESTATION DAO ==========
pub async fn create_prestation(
    pool: &PgPool,
    partenaire_id: Uuid,
    request: &CreatePrestationRequest,
) -> Result<Prestation, sqlx::Error> {
    let media_urls = request.media_urls.clone();
    let details = request
        .details
        .clone()
        .unwrap_or_else(|| Value::Object(Default::default()));

    let row = sqlx::query_as::<_, PrestationRow>(
        "INSERT INTO prestations (
            partenaire_id, type_service, name, price, cuisine_category, capacity,
            is_available, media_urls, details
         ) VALUES (
            $1, $2::service_type_enum, $3, $4, $5, $6,
            $7, $8, $9
         )
         RETURNING id, partenaire_id, type_service::TEXT AS type_service, name,
                   price::DOUBLE PRECISION AS price,
                   cuisine_category, capacity, is_available, media_urls, details,
                   created_at, updated_at",
    )
    .bind(partenaire_id)
    .bind(&request.type_service)
    .bind(&request.name)
    .bind(request.price)
    .bind(&request.cuisine_category)
    .bind(request.capacity)
    .bind(request.is_available.unwrap_or(true))
    .bind(Json(media_urls))
    .bind(Json(details))
    .fetch_one(pool)
    .await?;

    Ok(Prestation::from(row))
}

pub async fn toggle_prestation_availability(
    pool: &PgPool,
    prestation_id: Uuid,
    partenaire_id: Uuid,
) -> Result<Option<Prestation>, sqlx::Error> {
    let row = sqlx::query_as::<_, PrestationRow>(
        "UPDATE prestations
         SET is_available = NOT is_available,
             updated_at = now()
         WHERE id = $1
           AND partenaire_id = $2
         RETURNING id, partenaire_id, type_service::TEXT AS type_service, name,
                   price::DOUBLE PRECISION AS price,
                   cuisine_category, capacity, is_available, media_urls, details,
                   created_at, updated_at",
    )
    .bind(prestation_id)
    .bind(partenaire_id)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(Prestation::from))
}

pub async fn list_partner_catalog_prestations(
    pool: &PgPool,
    ids: Option<&[Uuid]>,
    partner_id: Option<Uuid>,
    type_service: Option<&str>,
) -> Result<Vec<PartnerCatalogPrestation>, sqlx::Error> {
    let mut query = QueryBuilder::<Postgres>::new(
        "SELECT
            p.id,
            p.partenaire_id AS partner_id,
            pa.nom_entreprise AS partner_name,
            pa.type_partenaire::TEXT AS partner_type,
            pa.is_boosted AS partner_is_boosted,
            jsonb_build_object(
                'latitude', pa.latitude,
                'longitude', pa.longitude
            ) AS partner_address_gps,
            p.type_service::TEXT AS type_service,
            p.name,
            p.price::DOUBLE PRECISION AS price,
            p.cuisine_category,
            p.capacity,
            p.is_available,
            p.media_urls,
            p.details
         FROM prestations p
         INNER JOIN partenaires pa ON pa.id = p.partenaire_id
         WHERE 1 = 1",
    );

    if ids.is_none() {
        query.push(" AND p.is_available = TRUE");
    }

    if let Some(type_service) = type_service.filter(|value| !value.trim().is_empty()) {
        query.push(" AND p.type_service::TEXT = ");
        query.push_bind(type_service);
    }

    if let Some(partner_id) = partner_id {
        query.push(" AND p.partenaire_id = ");
        query.push_bind(partner_id);
    }

    if let Some(ids) = ids.filter(|values| !values.is_empty()) {
        query.push(" AND p.id IN (");
        let mut separated = query.separated(", ");
        for id in ids {
            separated.push_bind(id);
        }
        separated.push_unseparated(")");
    }

    query.push(" ORDER BY pa.is_boosted DESC, p.updated_at DESC");

    let rows = query
        .build_query_as::<PartnerCatalogPrestationRow>()
        .fetch_all(pool)
        .await?;

    Ok(rows
        .into_iter()
        .map(PartnerCatalogPrestation::from)
        .collect())
}

#[allow(clippy::too_many_arguments)]
pub async fn create_pack_ticket_in_transaction(
    tx: &mut Transaction<'_, Postgres>,
    user_id: Uuid,
    ticket_id: Uuid,
    partner_id: Option<Uuid>,
    prestation_id: Option<Uuid>,
    cart_item_id: &str,
    service_type: &str,
    name: &str,
    token: &str,
    issued_at: chrono::DateTime<Utc>,
    expires_at: chrono::DateTime<Utc>,
    reservation_start: Option<chrono::DateTime<Utc>>,
    reservation_end: Option<chrono::DateTime<Utc>>,
) -> Result<PackTicket, sqlx::Error> {
    let row = sqlx::query_as::<_, PackTicketRow>(
        "WITH inserted AS (
            INSERT INTO pack_tickets (
                ticket_id, user_id, partner_id, prestation_id, cart_item_id, service_type,
                name, token, issued_at, expires_at, reservation_start, reservation_end
            ) VALUES (
                $1, $2, $3, $4, $5, $6,
                $7, $8, $9, $10, $11, $12
            )
            RETURNING ticket_id, cart_item_id, prestation_id, partner_id, service_type,
                      name, token, issued_at, expires_at, reservation_start, reservation_end
         )
         SELECT
            i.ticket_id,
            i.cart_item_id,
            i.prestation_id,
            i.partner_id,
            i.service_type,
            i.name,
            i.token,
            i.issued_at,
            i.expires_at,
            i.reservation_start,
            i.reservation_end,
            pa.wifi_ssid,
            pa.wifi_password_encrypted,
            CASE
                WHEN pa.id IS NULL THEN NULL
                ELSE jsonb_build_object(
                    'latitude', pa.latitude,
                    'longitude', pa.longitude
                )
            END AS partner_address_gps
         FROM inserted i
         LEFT JOIN partenaires pa ON pa.id = i.partner_id",
    )
    .bind(ticket_id)
    .bind(user_id)
    .bind(partner_id)
    .bind(prestation_id)
    .bind(cart_item_id)
    .bind(service_type)
    .bind(name)
    .bind(token)
    .bind(issued_at)
    .bind(expires_at)
    .bind(reservation_start)
    .bind(reservation_end)
    .fetch_one(&mut **tx)
    .await?;

    Ok(PackTicket::from(row))
}

pub async fn get_issued_pack_ticket_for_cart_item(
    pool: &PgPool,
    user_id: Uuid,
    cart_item_id: &str,
) -> Result<Option<PackTicket>, sqlx::Error> {
    let row = sqlx::query_as::<_, PackTicketRow>(
        "SELECT
            pt.ticket_id,
            pt.cart_item_id,
            pt.prestation_id,
            pt.partner_id,
            pt.service_type,
            pt.name,
            pt.token,
            pt.issued_at,
            pt.expires_at,
            pt.reservation_start,
            pt.reservation_end,
            pa.wifi_ssid,
            pa.wifi_password_encrypted,
            CASE
                WHEN pa.id IS NULL THEN NULL
                ELSE jsonb_build_object(
                    'latitude', pa.latitude,
                    'longitude', pa.longitude
                )
            END AS partner_address_gps
         FROM pack_tickets pt
         LEFT JOIN partenaires pa ON pa.id = pt.partner_id
         WHERE pt.user_id = $1
           AND pt.cart_item_id = $2
           AND pt.status = 'issued'
           AND pt.expires_at > now()
         ORDER BY pt.issued_at DESC
         LIMIT 1",
    )
    .bind(user_id)
    .bind(cart_item_id)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(PackTicket::from))
}

// ========== VOYAGE DAO ==========
pub async fn create_voyage(
    pool: &PgPool,
    user_id: Uuid,
    title: &str,
    description: Option<&str>,
    start_date: Option<NaiveDate>,
    end_date: Option<NaiveDate>,
) -> Result<Voyage, sqlx::Error> {
    sqlx::query_as::<_, Voyage>(
        "INSERT INTO voyages (user_id, title, description, start_date, end_date)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, user_id, title, description, start_date, end_date, created_at",
    )
    .bind(user_id)
    .bind(title)
    .bind(description)
    .bind(start_date)
    .bind(end_date)
    .fetch_one(pool)
    .await
}

pub async fn get_all_voyages_for_user(
    pool: &PgPool,
    user_id: Uuid,
) -> Result<Vec<Voyage>, sqlx::Error> {
    sqlx::query_as::<_, Voyage>(
        "SELECT id, user_id, title, description, start_date, end_date, created_at
         FROM voyages
         WHERE user_id = $1
         ORDER BY created_at DESC",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await
}

pub async fn get_voyage_by_id_and_user(
    pool: &PgPool,
    id: Uuid,
    user_id: Uuid,
) -> Result<Option<Voyage>, sqlx::Error> {
    sqlx::query_as::<_, Voyage>(
        "SELECT id, user_id, title, description, start_date, end_date, created_at
         FROM voyages
         WHERE id = $1 AND user_id = $2",
    )
    .bind(id)
    .bind(user_id)
    .fetch_optional(pool)
    .await
}

// ========== DRIVER DAO ==========
pub async fn get_all_drivers(pool: &PgPool) -> Result<Vec<Driver>, sqlx::Error> {
    let rows = sqlx::query_as::<_, DriverRow>(
        "SELECT id, name, phone_number, rating, review_count, vehicle_type,
                price::DOUBLE PRECISION AS price, capacity, license_plate,
                vehicle_color, status, current_location, eta, created_at
         FROM drivers
         ORDER BY created_at DESC",
    )
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(Driver::from).collect())
}

pub async fn list_nearby_drivers(pool: &PgPool) -> Result<Vec<Driver>, sqlx::Error> {
    let rows = sqlx::query_as::<_, DriverRow>(
        "SELECT id, name, phone_number, rating, review_count, vehicle_type,
                price::DOUBLE PRECISION AS price, capacity, license_plate,
                vehicle_color, status, current_location, eta, created_at
         FROM drivers
         WHERE status = 'available'
         ORDER BY eta ASC, rating DESC, created_at DESC",
    )
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(Driver::from).collect())
}

// ========== RIDE DAO ==========
pub async fn list_user_rides(pool: &PgPool, user_id: Uuid) -> Result<Vec<Ride>, sqlx::Error> {
    sync_active_rides_for_user(pool, user_id).await?;
    fetch_rides_for_user(pool, user_id).await
}

pub async fn get_ride_by_id_for_user(
    pool: &PgPool,
    ride_id: Uuid,
    user_id: Uuid,
) -> Result<Option<Ride>, sqlx::Error> {
    sync_ride_runtime(pool, ride_id, user_id).await?;
    fetch_ride_by_id(pool, ride_id, user_id).await
}

pub async fn create_ride_session(
    pool: &PgPool,
    user_id: Uuid,
    request: &CreateRideRequest,
) -> Result<Ride, AppError> {
    let terms = build_pricing_terms(request);
    let requested_duration_minutes = request.requested_duration_minutes.max(30);
    let estimated_time_text = request
        .estimated_time_text
        .clone()
        .unwrap_or_else(|| format_duration_label(requested_duration_minutes));
    let scheduled_start = if terms.schedule_type == "scheduled" {
        request.scheduled_start
    } else {
        None
    };
    let now = Utc::now();
    let has_assigned_driver = request.driver_id.is_some();
    let initial_status = if !has_assigned_driver {
        "requested".to_string()
    } else if scheduled_start.map(|start| start > now).unwrap_or(false) {
        "scheduled".to_string()
    } else {
        "accepted".to_string()
    };
    let started_at = if initial_status == "scheduled" {
        scheduled_start
    } else {
        Some(now)
    };

    let mut tx = pool.begin().await?;

    if let Some(driver_id) = request.driver_id {
        let locked_driver = sqlx::query_as::<_, (String, i32, String)>(
            "SELECT vehicle_type, capacity, status
             FROM drivers
             WHERE id = $1
             FOR UPDATE",
        )
        .bind(driver_id)
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(AppError::NotFound)?;

        if locked_driver.2 != "available" {
            return Err(AppError::Conflict(
                "The selected driver is no longer available".to_string(),
            ));
        }

        if locked_driver.1 < request.passenger_count {
            return Err(AppError::Conflict(format!(
                "The selected driver can only handle {} passenger(s)",
                locked_driver.1
            )));
        }

        let requires_mini_car =
            request.group_context.eq_ignore_ascii_case("group") && request.passenger_count >= 10;
        if requires_mini_car && !locked_driver.0.eq_ignore_ascii_case("mini-car") {
            return Err(AppError::Conflict(
                "A mini-car driver is required for groups of 10 or more passengers".to_string(),
            ));
        }

        let claimed = sqlx::query(
            "UPDATE drivers
             SET status = 'busy'
             WHERE id = $1 AND status = 'available'",
        )
        .bind(driver_id)
        .execute(&mut *tx)
        .await?;

        if claimed.rows_affected() != 1 {
            return Err(AppError::Conflict(
                "The selected driver was booked by another customer".to_string(),
            ));
        }
    }

    let ride_id = sqlx::query_as::<_, (Uuid,)>(
        "INSERT INTO rides (
            user_id, driver_id, origin, destination, pickup_location, destination_location,
            ride_type, schedule_type, scheduled_start, group_context, passenger_count,
            requested_duration_minutes, vehicle_type, seat_capacity, estimated_price,
            hourly_rate, estimated_time_text, status, overtime_minutes, overtime_amount,
            final_amount, payment_status, penalty_amount, restriction_reason,
            auto_charge_attempted_at, created_at, started_at, completed_at, updated_at
         ) VALUES (
            $1, $2, $3, $4, $5, $6,
            $7, $8, $9, $10, $11,
            $12, $13, $14, $15,
            $16, $17, $18, 0, 0,
            $19, 'included', 0, NULL,
            NULL, now(), $20, NULL, now()
         )
         RETURNING id",
    )
    .bind(user_id)
    .bind(request.driver_id)
    .bind(request.pickup_location.address.clone())
    .bind(request.destination_location.address.clone())
    .bind(Json(request.pickup_location.clone()))
    .bind(Json(request.destination_location.clone()))
    .bind(terms.ride_type)
    .bind(terms.schedule_type)
    .bind(scheduled_start)
    .bind(terms.group_context)
    .bind(request.passenger_count.max(1))
    .bind(requested_duration_minutes)
    .bind(terms.vehicle_type)
    .bind(terms.seat_capacity)
    .bind(terms.estimated_price)
    .bind(terms.hourly_rate)
    .bind(estimated_time_text)
    .bind(initial_status)
    .bind(terms.estimated_price)
    .bind(started_at)
    .fetch_one(&mut *tx)
    .await?
    .0;

    tx.commit().await?;

    get_ride_by_id_for_user(pool, ride_id, user_id)
        .await?
        .ok_or(AppError::NotFound)
}

pub async fn create_legacy_ride(
    pool: &PgPool,
    user_id: Uuid,
    origin: &str,
    destination: &str,
) -> Result<Ride, AppError> {
    let request = CreateRideRequest {
        driver_id: None,
        pickup_location: default_location(origin),
        destination_location: default_location(destination),
        ride_type: "withDriver".to_string(),
        schedule_type: "immediate".to_string(),
        scheduled_start: None,
        group_context: "soloBusiness".to_string(),
        passenger_count: 1,
        requested_duration_minutes: 60,
        vehicle_type: "comfort".to_string(),
        seat_capacity: Some(4),
        quoted_price: DEFAULT_HOURLY_RATE,
        estimated_time_text: Some("1h".to_string()),
    };

    create_ride_session(pool, user_id, &request).await
}

pub async fn cancel_ride(
    pool: &PgPool,
    ride_id: Uuid,
    user_id: Uuid,
) -> Result<Option<Ride>, sqlx::Error> {
    let mut tx = pool.begin().await?;

    let row = sqlx::query_as::<_, (Option<Uuid>,)>(
        "UPDATE rides
         SET status = 'cancelled',
             completed_at = COALESCE(completed_at, now()),
             updated_at = now()
         WHERE id = $1
           AND user_id = $2
           AND status NOT IN ('cancelled', 'completed', 'restricted')
         RETURNING driver_id",
    )
    .bind(ride_id)
    .bind(user_id)
    .fetch_optional(&mut *tx)
    .await?;

    let Some((driver_id,)) = row else {
        tx.rollback().await?;
        return Ok(None);
    };

    if let Some(driver_id) = driver_id {
        sqlx::query("UPDATE drivers SET status = 'available' WHERE id = $1")
            .bind(driver_id)
            .execute(&mut *tx)
            .await?;
    }

    tx.commit().await?;
    fetch_ride_by_id(pool, ride_id, user_id).await
}

pub async fn complete_ride(
    pool: &PgPool,
    ride_id: Uuid,
    user_id: Uuid,
) -> Result<Option<RideSettlementResponse>, sqlx::Error> {
    let mut tx = pool.begin().await?;
    sync_ride_runtime_tx(&mut tx, ride_id, user_id).await?;

    let financial = sqlx::query_as::<_, RideFinancialRow>(
        "SELECT driver_id, estimated_price, overtime_amount, penalty_amount
         FROM rides
         WHERE id = $1 AND user_id = $2
         FOR UPDATE",
    )
    .bind(ride_id)
    .bind(user_id)
    .fetch_optional(&mut *tx)
    .await?;

    let Some(financial) = financial else {
        tx.rollback().await?;
        return Ok(None);
    };

    let extra_due = financial.overtime_amount.max(0.0);
    let mut payment_status = if extra_due > 0.0 {
        "charged".to_string()
    } else {
        "included".to_string()
    };
    let mut user_restricted = false;
    let mut restriction_reason: Option<String> = None;
    let mut penalty_amount = financial.penalty_amount.max(0.0);
    let mut infraction_id = None;
    let auto_charge_attempted_at = if extra_due > 0.0 {
        Some(Utc::now())
    } else {
        None
    };

    if extra_due > 0.0 {
        let user_balance = sqlx::query_as::<_, UserBalanceRow>(
            "SELECT account_balance
             FROM users
             WHERE id = $1
             FOR UPDATE",
        )
        .bind(user_id)
        .fetch_one(&mut *tx)
        .await?;

        if user_balance.account_balance >= extra_due {
            sqlx::query(
                "UPDATE users
                 SET account_balance = account_balance - $1
                 WHERE id = $2",
            )
            .bind(extra_due)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;
        } else {
            user_restricted = true;
            payment_status = "failed".to_string();
            penalty_amount += PAYMENT_FINE_AMOUNT;
            restriction_reason = Some(format!(
                "Solde insuffisant pour solder automatiquement {:.0} FCFA d'overtime.",
                extra_due
            ));

            sqlx::query(
                "UPDATE users
                 SET is_restricted = TRUE,
                     restriction_reason = $1,
                     penalty_balance = penalty_balance + $2,
                     active_fine_amount = active_fine_amount + $2
                 WHERE id = $3",
            )
            .bind(restriction_reason.clone())
            .bind(PAYMENT_FINE_AMOUNT)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;

            infraction_id = Some(
                sqlx::query_as::<_, (Uuid,)>(
                    "INSERT INTO ride_infractions (
                        ride_id, user_id, infraction_type, description, overtime_amount, fine_amount
                     ) VALUES (
                        $1, $2, 'payment_default', $3, $4, $5
                     )
                     RETURNING id",
                )
                .bind(ride_id)
                .bind(user_id)
                .bind(
                    restriction_reason
                        .clone()
                        .unwrap_or_else(|| "Defaut de paiement sur overtime".to_string()),
                )
                .bind(extra_due)
                .bind(PAYMENT_FINE_AMOUNT)
                .fetch_one(&mut *tx)
                .await?
                .0,
            );
        }
    }

    let final_amount = financial.estimated_price + extra_due + penalty_amount;
    let next_status = if user_restricted {
        "restricted"
    } else {
        "completed"
    };

    sqlx::query(
        "UPDATE rides
         SET status = $1,
             payment_status = $2,
             penalty_amount = $3,
             restriction_reason = $4,
             auto_charge_attempted_at = COALESCE($5, auto_charge_attempted_at),
             final_amount = $6,
             completed_at = COALESCE(completed_at, now()),
             updated_at = now()
         WHERE id = $7 AND user_id = $8",
    )
    .bind(next_status)
    .bind(payment_status)
    .bind(penalty_amount)
    .bind(restriction_reason.clone())
    .bind(auto_charge_attempted_at)
    .bind(final_amount)
    .bind(ride_id)
    .bind(user_id)
    .execute(&mut *tx)
    .await?;

    if let Some(driver_id) = financial.driver_id {
        sqlx::query("UPDATE drivers SET status = 'available' WHERE id = $1")
            .bind(driver_id)
            .execute(&mut *tx)
            .await?;
    }

    tx.commit().await?;

    let Some(ride) = fetch_ride_by_id(pool, ride_id, user_id).await? else {
        return Ok(None);
    };

    Ok(Some(RideSettlementResponse {
        ride,
        user_restricted,
        restriction_reason,
        infraction_id,
    }))
}

// ========== HOTEL DAO ==========
pub async fn get_hotels_by_city(
    pool: &PgPool,
    city: Option<&str>,
) -> Result<Vec<Hotel>, sqlx::Error> {
    let rows = if let Some(city) = city.filter(|value| !value.trim().is_empty()) {
        sqlx::query_as::<_, HotelRow>(
            "SELECT id, name, city, address, description, rating, review_count,
                    price_per_night::DOUBLE PRECISION AS price_per_night, capacity,
                    latitude, longitude, amenities, image_urls, video_360_urls,
                    is_featured, type, wifi_ssid, wifi_password_encrypted, created_at
             FROM hotels
             WHERE LOWER(city) = LOWER($1)
             ORDER BY is_featured DESC, rating DESC, created_at DESC",
        )
        .bind(city)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query_as::<_, HotelRow>(
            "SELECT id, name, city, address, description, rating, review_count,
                    price_per_night::DOUBLE PRECISION AS price_per_night, capacity,
                    latitude, longitude, amenities, image_urls, video_360_urls,
                    is_featured, type, wifi_ssid, wifi_password_encrypted, created_at
             FROM hotels
             ORDER BY is_featured DESC, rating DESC, created_at DESC",
        )
        .fetch_all(pool)
        .await?
    };

    Ok(rows.into_iter().map(Hotel::from).collect())
}

pub async fn get_rooms_by_hotel(pool: &PgPool, hotel_id: Uuid) -> Result<Vec<Room>, sqlx::Error> {
    let rows = sqlx::query_as::<_, RoomRow>(
        "SELECT id, hotel_id, room_type, capacity, price::DOUBLE PRECISION AS price,
                amenities, available,
                image_urls, video_360_urls, created_at
         FROM rooms
         WHERE hotel_id = $1
         ORDER BY created_at DESC",
    )
    .bind(hotel_id)
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(Room::from).collect())
}

// ========== RESERVATION DAO ==========
pub async fn create_reservation(
    pool: &PgPool,
    user_id: Uuid,
    room_id: Uuid,
    start_date: NaiveDate,
    end_date: NaiveDate,
) -> Result<Reservation, AppError> {
    if end_date <= start_date {
        return Err(AppError::BadRequest(
            "endDate must be later than startDate".to_string(),
        ));
    }

    let mut tx = pool.begin().await?;
    let room = sqlx::query_as::<_, (Uuid, i32, f64, bool)>(
        "SELECT hotel_id, capacity, price::DOUBLE PRECISION, available
         FROM rooms
         WHERE id = $1
         FOR UPDATE",
    )
    .bind(room_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    if !room.3 {
        return Err(AppError::Conflict(
            "This room is currently unavailable".to_string(),
        ));
    }

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
    .fetch_one(&mut *tx)
    .await?;

    if has_overlap {
        return Err(AppError::Conflict(
            "This room is already reserved for the selected dates".to_string(),
        ));
    }

    let row = sqlx::query_as::<_, ReservationRow>(
        "INSERT INTO reservations (
            user_id, hotel_id, room_id, capacity, price, start_date, end_date
         ) VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, user_id, hotel_id, room_id, capacity,
                   price::DOUBLE PRECISION AS price, start_date, end_date, created_at",
    )
    .bind(user_id)
    .bind(room.0)
    .bind(room_id)
    .bind(room.1)
    .bind(room.2)
    .bind(start_date)
    .bind(end_date)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Reservation::from(row))
}

pub async fn get_reservations_for_user(
    pool: &PgPool,
    user_id: Uuid,
) -> Result<Vec<Reservation>, sqlx::Error> {
    let rows = sqlx::query_as::<_, ReservationRow>(
        "SELECT id, user_id, hotel_id, room_id, capacity,
                price::DOUBLE PRECISION AS price, start_date, end_date, created_at
         FROM reservations
         WHERE user_id = $1
         ORDER BY created_at DESC",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(Reservation::from).collect())
}
