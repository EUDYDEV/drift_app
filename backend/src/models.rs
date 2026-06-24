use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

// ========== USER ==========
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
#[serde(rename_all = "camelCase")]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub full_name: String,
    pub account_balance: f64,
    pub penalty_balance: f64,
    pub active_fine_amount: f64,
    pub is_restricted: bool,
    pub restriction_reason: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    #[serde(alias = "fullName")]
    pub full_name: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub user: User,
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct ForgotPasswordRequest {
    pub email: String,
}

#[derive(Debug, Serialize)]
pub struct MessageResponse {
    pub message: String,
}

// ========== PARTNER ==========
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GeoPoint {
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Partner {
    pub id: Uuid,
    pub nom_entreprise: String,
    pub registre_commerce: String,
    pub telephone: String,
    pub adresse_gps: GeoPoint,
    pub latitude: f64,
    pub longitude: f64,
    pub type_partenaire: String,
    pub is_boosted: bool,
    pub wifi_ssid: Option<String>,
    #[allow(dead_code)]
    #[serde(skip_serializing)]
    pub wifi_password_encrypted: Option<String>,
    #[allow(dead_code)]
    #[serde(skip_serializing)]
    pub password_hash: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PartnerRegisterRequest {
    #[serde(alias = "nom_entreprise")]
    pub nom_entreprise: String,
    #[serde(alias = "registre_commerce")]
    pub registre_commerce: String,
    pub telephone: String,
    #[serde(alias = "adresse_gps")]
    pub adresse_gps: Option<GeoPoint>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    #[serde(alias = "type_partenaire")]
    pub type_partenaire: String,
    pub is_boosted: Option<bool>,
    #[serde(alias = "wifi_ssid")]
    pub wifi_ssid: Option<String>,
    #[serde(alias = "wifi_password_encrypted")]
    pub wifi_password_encrypted: Option<String>,
    pub password: String,
}

impl PartnerRegisterRequest {
    pub fn resolve_geo_point(&self) -> Option<GeoPoint> {
        self.adresse_gps
            .clone()
            .or_else(|| match (self.latitude, self.longitude) {
                (Some(latitude), Some(longitude)) => Some(GeoPoint {
                    latitude,
                    longitude,
                }),
                _ => None,
            })
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PartnerLoginRequest {
    pub telephone: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PartnerAuthResponse {
    pub partner: Partner,
    pub token: String,
}

// ========== PRESTATION ==========
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Prestation {
    pub id: Uuid,
    pub partenaire_id: Uuid,
    pub type_service: String,
    pub name: String,
    pub price: f64,
    pub cuisine_category: Option<String>,
    pub capacity: Option<i32>,
    pub is_available: bool,
    pub media_urls: Vec<String>,
    pub details: Value,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreatePrestationRequest {
    #[serde(alias = "type_service")]
    pub type_service: String,
    pub name: String,
    pub price: f64,
    #[serde(alias = "cuisine_category")]
    pub cuisine_category: Option<String>,
    pub capacity: Option<i32>,
    #[serde(alias = "is_available")]
    pub is_available: Option<bool>,
    #[serde(alias = "media_urls")]
    pub media_urls: Vec<String>,
    pub details: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PartnerCatalogPrestation {
    pub id: Uuid,
    pub partner_id: Uuid,
    pub partner_name: String,
    pub partner_type: String,
    pub partner_is_boosted: bool,
    pub partner_address_gps: GeoPoint,
    pub type_service: String,
    pub name: String,
    pub price: f64,
    pub cuisine_category: Option<String>,
    pub capacity: Option<i32>,
    pub is_available: bool,
    pub media_urls: Vec<String>,
    pub details: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PartnerWifiAccess {
    pub ssid: String,
    pub password_encrypted: String,
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PackTicketRequestItem {
    pub cart_item_id: String,
    pub prestation_id: Option<Uuid>,
    pub partner_id: Option<Uuid>,
    pub service_type: String,
    pub name: String,
    pub reservation_start: Option<chrono::DateTime<chrono::Utc>>,
    pub reservation_end: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct IssuePackTicketsRequest {
    pub items: Vec<PackTicketRequestItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PackTicket {
    pub ticket_id: Uuid,
    pub cart_item_id: String,
    pub prestation_id: Option<Uuid>,
    pub partner_id: Option<Uuid>,
    pub service_type: String,
    pub name: String,
    pub token: String,
    pub issued_at: chrono::DateTime<chrono::Utc>,
    pub expires_at: chrono::DateTime<chrono::Utc>,
    pub reservation_start: Option<chrono::DateTime<chrono::Utc>>,
    pub reservation_end: Option<chrono::DateTime<chrono::Utc>>,
    pub wifi_access: Option<PartnerWifiAccess>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct IssuePackTicketsResponse {
    pub tickets: Vec<PackTicket>,
}

// ========== VOYAGE ==========
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Voyage {
    pub id: Uuid,
    pub user_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub start_date: Option<chrono::NaiveDate>,
    pub end_date: Option<chrono::NaiveDate>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateVoyageRequest {
    pub title: String,
    pub description: Option<String>,
    pub start_date: Option<String>,
    pub end_date: Option<String>,
}

// ========== SHARED LOCATION ==========
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AppLocation {
    pub latitude: f64,
    pub longitude: f64,
    pub address: String,
    pub city: Option<String>,
    pub country: Option<String>,
}

// ========== DRIVER ==========
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Driver {
    pub id: Uuid,
    pub name: String,
    pub phone_number: String,
    pub rating: f64,
    pub review_count: i32,
    pub vehicle_type: String,
    pub price: f64,
    pub capacity: i32,
    pub license_plate: String,
    pub vehicle_color: String,
    pub status: String,
    pub current_location: AppLocation,
    pub eta: i32,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

// ========== RIDE ==========
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Ride {
    pub id: Uuid,
    pub user_id: Uuid,
    pub driver_id: Option<Uuid>,
    pub driver: Option<Driver>,
    pub origin: String,
    pub destination: String,
    pub pickup_location: AppLocation,
    pub destination_location: AppLocation,
    pub ride_type: String,
    pub schedule_type: String,
    pub scheduled_start: Option<chrono::DateTime<chrono::Utc>>,
    pub group_context: String,
    pub passenger_count: i32,
    pub requested_duration_minutes: i32,
    pub vehicle_type: String,
    pub seat_capacity: i32,
    pub estimated_price: f64,
    pub hourly_rate: f64,
    pub estimated_time_text: String,
    pub status: String,
    pub overtime_minutes: i32,
    pub overtime_amount: f64,
    pub final_amount: f64,
    pub payment_status: String,
    pub penalty_amount: f64,
    pub restriction_reason: Option<String>,
    pub auto_charge_attempted_at: Option<chrono::DateTime<chrono::Utc>>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub started_at: Option<chrono::DateTime<chrono::Utc>>,
    pub completed_at: Option<chrono::DateTime<chrono::Utc>>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
pub struct RequestRideRequest {
    pub origin: String,
    pub destination: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateRideRequest {
    pub driver_id: Option<Uuid>,
    pub pickup_location: AppLocation,
    pub destination_location: AppLocation,
    pub ride_type: String,
    pub schedule_type: String,
    pub scheduled_start: Option<chrono::DateTime<chrono::Utc>>,
    pub group_context: String,
    pub passenger_count: i32,
    pub requested_duration_minutes: i32,
    pub vehicle_type: String,
    pub seat_capacity: Option<i32>,
    pub quoted_price: f64,
    pub estimated_time_text: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RideSettlementResponse {
    pub ride: Ride,
    pub user_restricted: bool,
    pub restriction_reason: Option<String>,
    pub infraction_id: Option<Uuid>,
}

// ========== HOTEL ==========
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Hotel {
    pub id: Uuid,
    pub name: String,
    pub city: String,
    pub address: String,
    pub description: String,
    pub rating: f64,
    pub review_count: i32,
    pub price_per_night: f64,
    pub capacity: i32,
    pub latitude: f64,
    pub longitude: f64,
    pub amenities: Vec<String>,
    pub image_urls: Vec<String>,
    pub video_360_urls: Vec<String>,
    pub is_featured: bool,
    pub r#type: String,
    pub wifi_ssid: Option<String>,
    #[allow(dead_code)]
    #[serde(skip_serializing)]
    pub wifi_password_encrypted: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Room {
    pub id: Uuid,
    pub hotel_id: Uuid,
    #[serde(alias = "room_type", alias = "name")]
    pub room_type: String,
    pub capacity: i32,
    pub price: f64,
    pub amenities: Vec<String>,
    pub available: bool,
    pub image_urls: Vec<String>,
    pub video_360_urls: Vec<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

// ========== RESERVATION ==========
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Reservation {
    pub id: Uuid,
    pub user_id: Uuid,
    pub hotel_id: Uuid,
    pub room_id: Uuid,
    pub capacity: i32,
    pub price: f64,
    pub start_date: chrono::NaiveDate,
    pub end_date: chrono::NaiveDate,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
pub struct ReservationRequest {
    #[serde(alias = "roomId")]
    pub room_id: Uuid,
    #[serde(alias = "startDate")]
    pub start_date: String,
    #[serde(alias = "endDate")]
    pub end_date: String,
}

// ========== PAYMENT ==========
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PaymentMethodRequest {
    pub code: String,
    pub label: Option<String>,
    pub phone_number: Option<String>,
    pub holder_name: Option<String>,
    pub email: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CheckoutPackItemRequest {
    pub cart_item_id: String,
    pub item_type: String,
    pub service_type: String,
    pub name: String,
    pub subtitle: Option<String>,
    pub amount: f64,
    pub partner_id: Option<Uuid>,
    pub prestation_id: Option<Uuid>,
    pub reservation_start: Option<chrono::DateTime<chrono::Utc>>,
    pub reservation_end: Option<chrono::DateTime<chrono::Utc>>,
    pub metadata: Option<Value>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CheckoutPaymentRequest {
    pub total_amount: f64,
    pub currency: Option<String>,
    pub payment_method: PaymentMethodRequest,
    pub items: Vec<CheckoutPackItemRequest>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Payment {
    pub id: Uuid,
    pub user_id: Uuid,
    pub reservation_id: Option<Uuid>,
    pub reservation_ids: Vec<Uuid>,
    pub status: String,
    pub amount: f64,
    pub currency: String,
    pub payment_method_code: String,
    pub payment_method_label: Option<String>,
    pub payment_method_last4: Option<String>,
    pub payment_provider: String,
    pub provider_reference: String,
    pub failure_reason: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
    #[allow(dead_code)]
    #[serde(skip_serializing)]
    pub payment_method_token: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PaymentCheckoutResponse {
    pub payment: Payment,
    pub reservations: Vec<Reservation>,
    pub message: String,
}

// ========== JWT CLAIMS ==========
#[derive(Debug, Serialize, Deserialize)]
pub struct JwtClaims {
    pub sub: String,
    pub exp: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PackTicketJwtClaims {
    pub sub: String,
    pub exp: i64,
    pub ticket_id: String,
    pub partner_id: Option<String>,
    pub prestation_id: Option<String>,
    pub service_type: String,
}
