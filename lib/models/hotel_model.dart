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

  // Compatibility fields used by the "service" flow.
  final int reviewCount;
  final double pricePerNight;
  final String address;
  final String? image;
  final bool isFeatured;
  final String type;

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
    required this.imageSeeds,
    required this.amenities,
    required this.rooms,
    this.reviewCount = 0,
    double? pricePerNight,
    String? address,
    this.image,
    this.isFeatured = false,
    this.type = 'hotel',
  })  : pricePerNight = pricePerNight ?? priceValue.toDouble(),
        address = address ?? location;

  String get coverImage =>
      image ?? (imageSeeds.isNotEmpty ? imageSeeds.first : '');
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
    required String address,
    required super.amenities,
    super.image,
    super.isFeatured = false,
    super.type = 'hotel',
  }) : super(
          location: address,
          address: address,
          pricePerNight: pricePerNight,
          stars: _resolveStars(rating),
          priceDisplay: _formatPrice(pricePerNight),
          priceValue: pricePerNight.round(),
          category: _resolveCategory(type, isFeatured, rating),
          imageSeeds: image != null ? <String>[image] : const <String>[],
          rooms: const <RoomModel>[],
        );

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
}
