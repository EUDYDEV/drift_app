import 'location_model.dart';

class PartnerCatalogPrestation {
  final String id;
  final String partnerId;
  final String partnerName;
  final String partnerType;
  final bool partnerIsBoosted;
  final AppLocation partnerLocation;
  final String typeService;
  final String name;
  final double price;
  final String? cuisineCategory;
  final int? capacity;
  final bool isAvailable;
  final List<String> mediaUrls;
  final Map<String, dynamic> details;

  const PartnerCatalogPrestation({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.partnerType,
    required this.partnerIsBoosted,
    required this.partnerLocation,
    required this.typeService,
    required this.name,
    required this.price,
    required this.cuisineCategory,
    required this.capacity,
    required this.isAvailable,
    required this.mediaUrls,
    required this.details,
  });

  String? get cityHint =>
      _readString(details, 'city') ?? _readString(details, 'ville');

  factory PartnerCatalogPrestation.fromJson(Map<String, dynamic> json) {
    final gps = (json['partnerAddressGps'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final details = (json['details'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return PartnerCatalogPrestation(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      partnerName: json['partnerName']?.toString() ?? '',
      partnerType: json['partnerType']?.toString() ?? '',
      partnerIsBoosted: json['partnerIsBoosted'] as bool? ??
          json['partner_is_boosted'] as bool? ??
          false,
      partnerLocation: AppLocation(
        latitude: (gps['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (gps['longitude'] as num?)?.toDouble() ?? 0,
        address: _readString(details, 'address') ?? '',
        city: _readString(details, 'city') ?? _readString(details, 'ville'),
        country: _readString(details, 'country'),
      ),
      typeService: json['typeService']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      cuisineCategory: json['cuisineCategory']?.toString(),
      capacity: (json['capacity'] as num?)?.toInt(),
      isAvailable: json['isAvailable'] as bool? ?? false,
      mediaUrls: _readStringList(json['mediaUrls']),
      details: details,
    );
  }

  static List<String> _readStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  static String? _readString(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}
