class PartnerWifiAccessContext {
  final String ssid;
  final String passwordEncrypted;
  final double latitude;
  final double longitude;

  const PartnerWifiAccessContext({
    required this.ssid,
    required this.passwordEncrypted,
    required this.latitude,
    required this.longitude,
  });

  factory PartnerWifiAccessContext.fromJson(Map<String, dynamic> json) {
    return PartnerWifiAccessContext(
      ssid: json['ssid']?.toString() ?? '',
      passwordEncrypted: json['passwordEncrypted']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'passwordEncrypted': passwordEncrypted,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class IssuedPackTicket {
  final String ticketId;
  final String cartItemId;
  final String? prestationId;
  final String? partnerId;
  final String serviceType;
  final String name;
  final String token;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime? reservationStart;
  final DateTime? reservationEnd;
  final PartnerWifiAccessContext? wifiAccess;

  const IssuedPackTicket({
    required this.ticketId,
    required this.cartItemId,
    required this.prestationId,
    required this.partnerId,
    required this.serviceType,
    required this.name,
    required this.token,
    required this.issuedAt,
    required this.expiresAt,
    required this.reservationStart,
    required this.reservationEnd,
    required this.wifiAccess,
  });

  bool get hasWifiAccess => wifiAccess != null;

  bool isActiveAt(DateTime instant) {
    final utcInstant = instant.toUtc();
    final startsAt = reservationStart?.toUtc() ?? issuedAt.toUtc();
    final endsAt = reservationEnd?.toUtc() ?? expiresAt.toUtc();
    return !utcInstant.isBefore(startsAt) && utcInstant.isBefore(endsAt);
  }

  factory IssuedPackTicket.fromJson(Map<String, dynamic> json) {
    return IssuedPackTicket(
      ticketId: json['ticketId']?.toString() ?? '',
      cartItemId: json['cartItemId']?.toString() ?? '',
      prestationId: json['prestationId']?.toString(),
      partnerId: json['partnerId']?.toString(),
      serviceType: json['serviceType']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      issuedAt:
          DateTime.tryParse(json['issuedAt']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      reservationStart: json['reservationStart'] == null
          ? null
          : DateTime.tryParse(json['reservationStart'].toString())?.toUtc(),
      reservationEnd: json['reservationEnd'] == null
          ? null
          : DateTime.tryParse(json['reservationEnd'].toString())?.toUtc(),
      wifiAccess: json['wifiAccess'] is Map
          ? PartnerWifiAccessContext.fromJson(
              (json['wifiAccess'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'cartItemId': cartItemId,
      'prestationId': prestationId,
      'partnerId': partnerId,
      'serviceType': serviceType,
      'name': name,
      'token': token,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'reservationStart': reservationStart?.toIso8601String(),
      'reservationEnd': reservationEnd?.toIso8601String(),
      'wifiAccess': wifiAccess?.toJson(),
    };
  }
}
