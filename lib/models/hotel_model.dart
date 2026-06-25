import 'room_model.dart';

class HotelModel {
  final String id;
  final String name;
  final String city;
  final String location;
  final String description;
  final double rating;
  final int stars;
  final String priceDisplay;
  final int priceValue;
  final String category;
  final List<String> imageSeeds;
  final List<String> amenities;
  final List<RoomModel> rooms;

  final int reviewCount;
  final double pricePerNight;
  final int capacity;
  final String address;
  final double latitude;
  final double longitude;
  final bool isFeatured;
  final String type;
  final String? partnerId;
  final String source;
  final String? wifiSsid;
  final List<String> imageUrls;
  final List<String> video360Urls;
  final DateTime? createdAt;

  String? get image => imageUrls.isNotEmpty ? imageUrls.first : null;
  String get coverImage => image ?? '';

  HotelModel({
    required this.id,
    required this.name,
    required this.city,
    required this.location,
    required this.description,
    required this.rating,
    required this.stars,
    required this.priceDisplay,
    required this.priceValue,
    required this.category,
    required List<String> imageSeeds,
    required this.amenities,
    required this.rooms,
    this.reviewCount = 0,
    double? pricePerNight,
    this.capacity = 2,
    String? address,
    this.latitude = 0,
    this.longitude = 0,
    this.isFeatured = false,
    this.type = 'hotel',
    this.partnerId,
    this.source = 'hotel_api',
    this.wifiSsid,
    List<String>? imageUrls,
    List<String>? video360Urls,
    this.createdAt,
  })  : pricePerNight = pricePerNight ?? priceValue.toDouble(),
        address = address ?? location,
        imageUrls = imageUrls ?? List<String>.from(imageSeeds),
        video360Urls = video360Urls ?? const <String>[],
        imageSeeds = imageUrls ?? List<String>.from(imageSeeds);
}

class Hotel extends HotelModel {
  Hotel({
    required super.id,
    required super.name,
    required super.city,
    required super.description,
    required super.rating,
    required super.reviewCount,
    required double pricePerNight,
    super.capacity = 2,
    required String address,
    required super.amenities,
    super.latitude = 0,
    super.longitude = 0,
    super.isFeatured = false,
    super.type = 'hotel',
    super.partnerId,
    super.source = 'hotel_api',
    super.wifiSsid,
    List<String> imageUrls = const <String>[],
    List<String> video360Urls = const <String>[],
    super.createdAt,
    super.rooms = const <RoomModel>[],
  }) : super(
          location: address,
          address: address,
          pricePerNight: pricePerNight,
          stars: _resolveStars(rating),
          priceDisplay: _formatPrice(pricePerNight),
          priceValue: pricePerNight.round(),
          category: _resolveCategory(type, isFeatured, rating),
          imageSeeds: imageUrls,
          imageUrls: imageUrls,
          video360Urls: video360Urls,
        );

  factory Hotel.fromJson(Map<String, dynamic> json) {
    final imageUrls = _readStringList(json['imageUrls'] ?? json['image_urls']);
    final video360Urls =
        _readStringList(json['video360Urls'] ?? json['video_360_urls']);

    return Hotel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Hotel',
      city: json['city']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ??
          (json['review_count'] as num?)?.toInt() ??
          0,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ??
          (json['price_per_night'] as num?)?.toDouble() ??
          0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 2,
      address:
          (json['address'] ?? json['location'] ?? 'Adresse inconnue').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      amenities: _readStringList(json['amenities']),
      isFeatured: json['isFeatured'] as bool? ??
          json['is_featured'] as bool? ??
          false,
      type: (json['type'] ?? 'hotel').toString(),
      partnerId: (json['partnerId'] ?? json['partner_id'])?.toString(),
      source: (json['source'] ?? 'hotel_api').toString(),
      wifiSsid: (json['wifiSsid'] ?? json['wifi_ssid'])?.toString(),
      imageUrls: imageUrls,
      video360Urls: video360Urls,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'pricePerNight': pricePerNight,
      'capacity': capacity,
      'amenities': amenities,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'video360Urls': video360Urls,
      'isFeatured': isFeatured,
      'type': type,
      'partnerId': partnerId,
      'source': source,
      'wifiSsid': wifiSsid,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static String _formatPrice(double value) => '${value.round()} FCFA';

  static int _resolveStars(double rating) {
    if (rating >= 4.7) return 5;
    if (rating >= 4.0) return 4;
    return 3;
  }

  static String _resolveCategory(String type, bool isFeatured, double rating) {
    if (type == 'restaurant') return 'GASTRO';
    if (isFeatured) return 'PEPITE';
    if (rating >= 4.6) return 'PREMIUM';
    return 'CONFORT';
  }

  static List<String> _readStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return <String>[raw];
    }
    return const <String>[];
  }
}
