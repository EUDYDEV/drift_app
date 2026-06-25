use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    routing::{get, post, put},
    Json, Router,
};
use chrono::NaiveDate;
use serde::Deserialize;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    auth, db,
    error::AppError,
    models::{
        AuthResponse, CreatePrestationRequest, CreateRideRequest, CreateVoyageRequest, Driver,
        ForgotPasswordRequest, Hotel, IssuePackTicketsRequest, IssuePackTicketsResponse,
        LoginRequest, MessageResponse, PackTicket, Partner, PartnerAuthResponse,
        PartnerCatalogPrestation, PartnerLoginRequest, PartnerRegisterRequest, Prestation,
        RegisterRequest, RequestRideRequest, Reservation, ReservationRequest, Ride,
        RideSettlementResponse, Room, User, Voyage,
    },
};

#[derive(Debug, Deserialize)]
pub struct HotelListQuery {
    pub city: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CatalogPrestationsQuery {
    pub ids: Option<String>,
    pub partner_id: Option<String>,
    pub type_service: Option<String>,
}

pub fn auth_routes() -> Router<PgPool> {
    Router::new()
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/me", get(me))
        .route("/profile", get(me))
        .route("/forgot-password", post(forgot_password))
}

pub fn partner_routes() -> Router<PgPool> {
    Router::new()
        .route("/register", post(register_partner))
        .route("/login", post(login_partner))
        .route(
            "/catalog/prestations",
            get(list_partner_catalog_prestations),
        )
        .route("/v1/prestations", post(create_prestation))
        .route(
            "/v1/prestations/:id/toggle",
            put(toggle_prestation_availability),
        )
        .route(
            "/v1/prestations/:id/toggle-availability",
            put(toggle_prestation_availability),
        )
}

pub fn pack_routes() -> Router<PgPool> {
    Router::new().route("/tickets/issue", post(issue_pack_tickets))
}

pub async fn register(
    State(pool): State<PgPool>,
    Json(req): Json<RegisterRequest>,
) -> Result<(StatusCode, Json<AuthResponse>), AppError> {
    if db::get_user_by_email(&pool, &req.email).await?.is_some() {
        return Err(AppError::UserExists);
    }

    let password_hash = auth::hash_password(&req.password)?;
    let user = db::create_user(&pool, &req.email, &req.full_name, &password_hash).await?;
    let token = auth::create_jwt(user.id)?;

    Ok((StatusCode::CREATED, Json(AuthResponse { user, token })))
}

pub async fn login(
    State(pool): State<PgPool>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, AppError> {
    let (user_id, password_hash) = db::get_user_by_email(&pool, &req.email)
        .await?
        .ok_or(AppError::InvalidCredentials)?;

    if !auth::verify_password(&req.password, &password_hash)? {
        return Err(AppError::InvalidCredentials);
    }

    let user = db::get_user_by_id(&pool, user_id)
        .await?
        .ok_or(AppError::InvalidCredentials)?;

    let token = auth::create_jwt(user.id)?;
    Ok(Json(AuthResponse { user, token }))
}

pub async fn me(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<User>, AppError> {
    let user = db::get_user_by_id(&pool, auth_user.0)
        .await?
        .ok_or(AppError::Unauthorized)?;
    Ok(Json(user))
}

pub async fn forgot_password(
    Json(req): Json<ForgotPasswordRequest>,
) -> Result<Json<MessageResponse>, AppError> {
    let _email = req.email;

    Ok(Json(MessageResponse {
        message: "If an account exists for this email, a reset link will be sent.".to_string(),
    }))
}

pub async fn register_partner(
    State(pool): State<PgPool>,
    Json(req): Json<PartnerRegisterRequest>,
) -> Result<(StatusCode, Json<PartnerAuthResponse>), AppError> {
    if !is_valid_partner_type(&req.type_partenaire) {
        return Err(AppError::BadRequest(
            "typePartenaire must be one of transport, hotel, restaurant, cinema, loisir"
                .to_string(),
        ));
    }

    if req.nom_entreprise.trim().is_empty() {
        return Err(AppError::BadRequest(
            "nomEntreprise is required".to_string(),
        ));
    }

    if req.registre_commerce.trim().is_empty() {
        return Err(AppError::BadRequest(
            "registreCommerce is required".to_string(),
        ));
    }

    if req.telephone.trim().is_empty() {
        return Err(AppError::BadRequest("telephone is required".to_string()));
    }

    if req.password.trim().is_empty() {
        return Err(AppError::BadRequest("password is required".to_string()));
    }

    let adresse_gps = req.resolve_geo_point().ok_or_else(|| {
        AppError::BadRequest("latitude/longitude or adresseGps is required".to_string())
    })?;

    if !(-90.0..=90.0).contains(&adresse_gps.latitude) {
        return Err(AppError::BadRequest(
            "latitude must be between -90 and 90".to_string(),
        ));
    }

    if !(-180.0..=180.0).contains(&adresse_gps.longitude) {
        return Err(AppError::BadRequest(
            "longitude must be between -180 and 180".to_string(),
        ));
    }

    if db::get_partner_by_telephone(&pool, &req.telephone)
        .await?
        .is_some()
    {
        return Err(AppError::Conflict(
            "A partner with this telephone already exists".to_string(),
        ));
    }

    if db::get_partner_by_registre_commerce(&pool, &req.registre_commerce)
        .await?
        .is_some()
    {
        return Err(AppError::Conflict(
            "A partner with this registreCommerce already exists".to_string(),
        ));
    }

    let password_hash = auth::hash_password(&req.password)?;
    let partner = db::create_partner(
        &pool,
        &req.nom_entreprise,
        &req.registre_commerce,
        &req.telephone,
        &adresse_gps,
        &req.type_partenaire,
        req.is_boosted.unwrap_or(false),
        req.wifi_ssid.as_deref(),
        req.wifi_password_encrypted.as_deref(),
        &password_hash,
    )
    .await?;

    let token = auth::create_jwt(partner.id)?;
    Ok((
        StatusCode::CREATED,
        Json(PartnerAuthResponse { partner, token }),
    ))
}

pub async fn login_partner(
    State(pool): State<PgPool>,
    Json(req): Json<PartnerLoginRequest>,
) -> Result<Json<PartnerAuthResponse>, AppError> {
    let (partner_id, password_hash) = db::get_partner_auth_by_telephone(&pool, &req.telephone)
        .await?
        .ok_or(AppError::InvalidCredentials)?;

    if !auth::verify_password(&req.password, &password_hash)? {
        return Err(AppError::InvalidCredentials);
    }

    let partner = db::get_partner_by_id(&pool, partner_id)
        .await?
        .ok_or(AppError::InvalidCredentials)?;

    let token = auth::create_jwt(partner.id)?;
    Ok(Json(PartnerAuthResponse { partner, token }))
}

pub async fn create_prestation(
    State(pool): State<PgPool>,
    auth_partner: auth::AuthPartner,
    Json(req): Json<CreatePrestationRequest>,
) -> Result<(StatusCode, Json<Prestation>), AppError> {
    let partner: Partner = db::get_partner_by_id(&pool, auth_partner.0)
        .await?
        .ok_or(AppError::Unauthorized)?;

    if !is_valid_service_type(&req.type_service) {
        return Err(AppError::BadRequest(
            "typeService must be one of location_voiture, chambre_hotel, table_resto, plat_livraison, ticket_cinema, ticket_jeu"
                .to_string(),
        ));
    }

    if req.name.trim().is_empty() {
        return Err(AppError::BadRequest("name is required".to_string()));
    }

    if req.price < 0.0 {
        return Err(AppError::BadRequest(
            "price must be greater than or equal to 0".to_string(),
        ));
    }

    if req.capacity.is_some_and(|value| value <= 0) {
        return Err(AppError::BadRequest(
            "capacity must be greater than 0 when provided".to_string(),
        ));
    }

    if req.media_urls.iter().any(|value| value.trim().is_empty()) {
        return Err(AppError::BadRequest(
            "mediaUrls cannot contain empty values".to_string(),
        ));
    }

    let prestation = db::create_prestation(&pool, partner.id, &req).await?;
    Ok((StatusCode::CREATED, Json(prestation)))
}

pub async fn toggle_prestation_availability(
    State(pool): State<PgPool>,
    auth_partner: auth::AuthPartner,
    Path(id): Path<Uuid>,
) -> Result<Json<Prestation>, AppError> {
    let partner = db::get_partner_by_id(&pool, auth_partner.0)
        .await?
        .ok_or(AppError::Unauthorized)?;

    let prestation = db::toggle_prestation_availability(&pool, id, partner.id)
        .await?
        .ok_or(AppError::NotFound)?;

    Ok(Json(prestation))
}

pub async fn list_partner_catalog_prestations(
    State(pool): State<PgPool>,
    Query(query): Query<CatalogPrestationsQuery>,
) -> Result<Json<Vec<PartnerCatalogPrestation>>, AppError> {
    let ids = parse_uuid_list(query.ids.as_deref())?;
    let partner_id = match query.partner_id.as_deref().map(str::trim) {
        Some(raw) if !raw.is_empty() => Some(
            Uuid::parse_str(raw)
                .map_err(|_| AppError::BadRequest(format!("Invalid UUID: {raw}")))?,
        ),
        _ => None,
    };
    let prestations = db::list_partner_catalog_prestations(
        &pool,
        ids.as_deref(),
        partner_id,
        query.type_service.as_deref(),
    )
    .await?;
    Ok(Json(prestations))
}

pub async fn issue_pack_tickets(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<IssuePackTicketsRequest>,
) -> Result<(StatusCode, Json<IssuePackTicketsResponse>), AppError> {
    if req.items.is_empty() {
        return Err(AppError::BadRequest(
            "items must contain at least one prestation".to_string(),
        ));
    }

    let mut tickets: Vec<PackTicket> = Vec::with_capacity(req.items.len());

    for item in req.items {
        if item.cart_item_id.trim().is_empty() {
            return Err(AppError::BadRequest("cartItemId is required".to_string()));
        }

        if item.service_type.trim().is_empty() {
            return Err(AppError::BadRequest("serviceType is required".to_string()));
        }

        if item.name.trim().is_empty() {
            return Err(AppError::BadRequest("name is required".to_string()));
        }

        let ticket =
            db::get_issued_pack_ticket_for_cart_item(&pool, auth_user.0, &item.cart_item_id)
                .await?
                .ok_or_else(|| {
                    AppError::Conflict(format!(
                        "No paid ticket exists for cart item {}",
                        item.cart_item_id
                    ))
                })?;

        if !ticket.service_type.eq_ignore_ascii_case(&item.service_type)
            || item
                .prestation_id
                .is_some_and(|prestation_id| ticket.prestation_id != Some(prestation_id))
            || item
                .partner_id
                .is_some_and(|partner_id| ticket.partner_id != Some(partner_id))
            || item
                .reservation_start
                .is_some_and(|start| ticket.reservation_start != Some(start))
            || item
                .reservation_end
                .is_some_and(|end| ticket.reservation_end != Some(end))
        {
            return Err(AppError::BadRequest(format!(
                "Ticket ownership mismatch for cart item {}",
                item.cart_item_id
            )));
        }

        tickets.push(ticket);
    }

    Ok((
        StatusCode::CREATED,
        Json(IssuePackTicketsResponse { tickets }),
    ))
}

pub fn voyage_routes() -> Router<PgPool> {
    Router::new()
        .route("/", get(list_voyages).post(create_voyage))
        .route("/:id", get(get_voyage))
}

pub async fn list_voyages(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Vec<Voyage>>, AppError> {
    let voyages = db::get_all_voyages_for_user(&pool, auth_user.0).await?;
    Ok(Json(voyages))
}

pub async fn get_voyage(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<Voyage>, AppError> {
    let voyage = db::get_voyage_by_id_and_user(&pool, id, auth_user.0)
        .await?
        .ok_or(AppError::NotFound)?;
    Ok(Json(voyage))
}

pub async fn create_voyage(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<CreateVoyageRequest>,
) -> Result<(StatusCode, Json<Voyage>), AppError> {
    let start_date = req
        .start_date
        .as_deref()
        .and_then(|d| NaiveDate::parse_from_str(d, "%Y-%m-%d").ok());
    let end_date = req
        .end_date
        .as_deref()
        .and_then(|d| NaiveDate::parse_from_str(d, "%Y-%m-%d").ok());

    let voyage = db::create_voyage(
        &pool,
        auth_user.0,
        &req.title,
        req.description.as_deref(),
        start_date,
        end_date,
    )
    .await?;

    Ok((StatusCode::CREATED, Json(voyage)))
}

pub fn driver_routes() -> Router<PgPool> {
    Router::new().route("/", get(list_drivers))
}

pub async fn list_drivers(State(pool): State<PgPool>) -> Result<Json<Vec<Driver>>, AppError> {
    let drivers = db::get_all_drivers(&pool).await?;
    Ok(Json(drivers))
}

pub fn ride_routes() -> Router<PgPool> {
    Router::new()
        .route("/", get(list_rides).post(create_ride))
        .route("/nearby-drivers", get(list_nearby_drivers))
        .route("/:id", get(get_ride))
        .route("/:id/cancel", post(cancel_ride))
        .route("/:id/complete", post(complete_ride))
        .route("/request", post(request_ride))
}

pub async fn list_nearby_drivers(
    State(pool): State<PgPool>,
) -> Result<Json<Vec<Driver>>, AppError> {
    let drivers = db::list_nearby_drivers(&pool).await?;
    Ok(Json(drivers))
}

pub async fn list_rides(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Vec<Ride>>, AppError> {
    let rides = db::list_user_rides(&pool, auth_user.0).await?;
    Ok(Json(rides))
}

pub async fn get_ride(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<Ride>, AppError> {
    let ride = db::get_ride_by_id_for_user(&pool, id, auth_user.0)
        .await?
        .ok_or(AppError::NotFound)?;
    Ok(Json(ride))
}

pub async fn create_ride(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<CreateRideRequest>,
) -> Result<(StatusCode, Json<Ride>), AppError> {
    if req.passenger_count < 1 {
        return Err(AppError::BadRequest(
            "passengerCount must be at least 1".to_string(),
        ));
    }

    if req.requested_duration_minutes < 30 {
        return Err(AppError::BadRequest(
            "requestedDurationMinutes must be at least 30".to_string(),
        ));
    }

    if req.schedule_type.eq_ignore_ascii_case("scheduled") && req.scheduled_start.is_none() {
        return Err(AppError::BadRequest(
            "scheduledStart is required for scheduled rides".to_string(),
        ));
    }

    let ride = db::create_ride_session(&pool, auth_user.0, &req).await?;
    Ok((StatusCode::CREATED, Json(ride)))
}

pub async fn request_ride(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<RequestRideRequest>,
) -> Result<(StatusCode, Json<Ride>), AppError> {
    let ride = db::create_legacy_ride(&pool, auth_user.0, &req.origin, &req.destination).await?;
    Ok((StatusCode::CREATED, Json(ride)))
}

pub async fn cancel_ride(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<Ride>, AppError> {
    let ride = db::cancel_ride(&pool, id, auth_user.0)
        .await?
        .ok_or(AppError::NotFound)?;
    Ok(Json(ride))
}

pub async fn complete_ride(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<RideSettlementResponse>, AppError> {
    let settlement = db::complete_ride(&pool, id, auth_user.0)
        .await?
        .ok_or(AppError::NotFound)?;
    Ok(Json(settlement))
}

pub fn hotel_routes() -> Router<PgPool> {
    Router::new()
        .route("/", get(list_hotels))
        .route("/:hotel_id/rooms", get(list_rooms_by_hotel))
}

pub async fn list_hotels(
    State(pool): State<PgPool>,
    Query(query): Query<HotelListQuery>,
) -> Result<Json<Vec<Hotel>>, AppError> {
    let hotels = db::get_hotels_by_city(&pool, query.city.as_deref()).await?;
    Ok(Json(hotels))
}

pub async fn list_rooms_by_hotel(
    State(pool): State<PgPool>,
    Path(hotel_id): Path<Uuid>,
) -> Result<Json<Vec<Room>>, AppError> {
    let rooms = db::get_rooms_by_hotel(&pool, hotel_id).await?;
    Ok(Json(rooms))
}

pub fn reservation_routes() -> Router<PgPool> {
    Router::new().route("/", get(list_reservations).post(create_reservation))
}

pub async fn list_reservations(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
) -> Result<Json<Vec<Reservation>>, AppError> {
    let reservations = db::get_reservations_for_user(&pool, auth_user.0).await?;
    Ok(Json(reservations))
}

pub async fn create_reservation(
    State(pool): State<PgPool>,
    auth_user: auth::AuthUser,
    Json(req): Json<ReservationRequest>,
) -> Result<(StatusCode, Json<Reservation>), AppError> {
    let start_date = NaiveDate::parse_from_str(&req.start_date, "%Y-%m-%d")
        .map_err(|_| AppError::Internal("Invalid start_date format".to_string()))?;
    let end_date = NaiveDate::parse_from_str(&req.end_date, "%Y-%m-%d")
        .map_err(|_| AppError::Internal("Invalid end_date format".to_string()))?;

    if end_date <= start_date {
        return Err(AppError::BadRequest(
            "endDate must be later than startDate".to_string(),
        ));
    }

    let reservation =
        db::create_reservation(&pool, auth_user.0, req.room_id, start_date, end_date).await?;
    Ok((StatusCode::CREATED, Json(reservation)))
}

fn is_valid_partner_type(value: &str) -> bool {
    matches!(
        value,
        "transport" | "hotel" | "restaurant" | "cinema" | "loisir"
    )
}

fn is_valid_service_type(value: &str) -> bool {
    matches!(
        value,
        "location_voiture"
            | "chambre_hotel"
            | "table_resto"
            | "plat_livraison"
            | "ticket_cinema"
            | "ticket_jeu"
    )
}

fn parse_uuid_list(raw: Option<&str>) -> Result<Option<Vec<Uuid>>, AppError> {
    let Some(raw) = raw else {
        return Ok(None);
    };

    let ids = raw
        .split(',')
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(|value| {
            Uuid::parse_str(value)
                .map_err(|_| AppError::BadRequest(format!("Invalid UUID: {value}")))
        })
        .collect::<Result<Vec<_>, _>>()?;

    if ids.is_empty() {
        Ok(None)
    } else {
        Ok(Some(ids))
    }
}
