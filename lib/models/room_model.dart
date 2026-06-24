class RoomModel {
  final String id;
  final String name;
  final String priceDisplay;
  final int priceValue;
  final String imageSeed;
  final List<String> gallerySeeds;

  final String? hotelId;
  final String? partnerId;
  final String? prestationId;
  final String roomType;
  final int capacity;
  final double price;
  final List<String> amenities;
  final bool available;
  final List<String> imageUrls;
  final List<String> video360Urls;
  final DateTime? createdAt;

  String? get image => imageUrls.isNotEmpty ? imageUrls.first : null;
  String? get virtualTourUrl =>
      video360Urls.isNotEmpty ? video360Urls.first : null;

  RoomModel({
    required this.id,
    required this.name,
    required this.priceDisplay,
    required this.priceValue,
    required this.imageSeed,
    required List<String> gallerySeeds,
    this.hotelId,
    this.partnerId,
    this.prestationId,
    String? roomType,
    this.capacity = 2,
    double? price,
    this.amenities = const <String>[],
    this.available = true,
    List<String>? imageUrls,
    List<String>? video360Urls,
    this.createdAt,
    String? image,
    String? virtualTourUrl,
  })  : roomType = roomType ?? name,
        price = price ?? priceValue.toDouble(),
        imageUrls = imageUrls ??
            _resolveImageUrls(
              image: image,
              gallerySeeds: gallerySeeds,
              imageSeed: imageSeed,
            ),
        video360Urls = video360Urls ??
            _resolveVideoUrls(
              virtualTourUrl: virtualTourUrl,
            ),
        gallerySeeds = _resolveGallerySeeds(
          rawGallerySeeds: gallerySeeds,
          imageUrls: imageUrls,
          image: image,
          imageSeed: imageSeed,
        );

  static List<String> _resolveImageUrls({
    required String? image,
    required List<String> gallerySeeds,
    required String imageSeed,
  }) {
    if (image != null && image.isNotEmpty) return <String>[image];
    if (gallerySeeds.isNotEmpty) return List<String>.from(gallerySeeds);
    if (imageSeed.isNotEmpty) return <String>[imageSeed];
    return const <String>[];
  }

  static List<String> _resolveGallerySeeds({
    required List<String> rawGallerySeeds,
    required List<String>? imageUrls,
    required String? image,
    required String imageSeed,
  }) {
    if (rawGallerySeeds.isNotEmpty) return List<String>.from(rawGallerySeeds);
    if (imageUrls != null && imageUrls.isNotEmpty) {
      return List<String>.from(imageUrls);
    }
    if (image != null && image.isNotEmpty) return <String>[image];
    if (imageSeed.isNotEmpty) return <String>[imageSeed];
    return const <String>[];
  }

  static List<String> _resolveVideoUrls({
    required String? virtualTourUrl,
  }) {
    if (virtualTourUrl != null && virtualTourUrl.isNotEmpty) {
      return <String>[virtualTourUrl];
    }
    return const <String>[];
  }
}

class Room extends RoomModel {
  Room({
    required super.id,
    String? name,
    required String roomType,
    required super.capacity,
    required double price,
    required super.amenities,
    required super.available,
    super.hotelId,
    super.partnerId,
    super.prestationId,
    List<String> imageUrls = const <String>[],
    List<String> video360Urls = const <String>[],
    super.createdAt,
  }) : super(
          name: (name != null && name.isNotEmpty) ? name : roomType,
          roomType: roomType,
          price: price,
          priceDisplay: '${price.round()} FCFA',
          priceValue: price.round(),
          imageSeed: imageUrls.isNotEmpty ? imageUrls.first : '',
          gallerySeeds: imageUrls,
          imageUrls: imageUrls,
          video360Urls: video360Urls,
        );

  factory Room.fromJson(Map<String, dynamic> json) {
    final imageUrls = _readStringList(json['imageUrls'] ?? json['image_urls']);
    final video360Urls =
        _readStringList(json['video360Urls'] ?? json['video_360_urls']);
    final roomName =
        (json['name'] ?? json['roomType'] ?? json['room_type'] ?? 'Chambre Standard')
            .toString();
    final roomType =
        (json['roomType'] ?? json['room_type'] ?? json['name'] ?? 'Chambre Standard')
            .toString();

    return Room(
      id: json['id']?.toString() ?? '',
      hotelId: json['hotelId']?.toString() ?? json['hotel_id']?.toString(),
      partnerId:
          json['partnerId']?.toString() ?? json['partner_id']?.toString(),
      prestationId: json['prestationId']?.toString() ??
          json['prestation_id']?.toString(),
      name: roomName,
      roomType: roomType,
      capacity: (json['capacity'] as num?)?.toInt() ?? 2,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      amenities: _readStringList(json['amenities']),
      available: json['available'] as bool? ??
          json['is_available'] as bool? ??
          true,
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
      'hotelId': hotelId,
      'partnerId': partnerId,
      'prestationId': prestationId,
      'name': name,
      'roomType': roomType,
      'capacity': capacity,
      'price': price,
      'amenities': amenities,
      'available': available,
      'imageUrls': imageUrls,
      'video360Urls': video360Urls,
      'createdAt': createdAt?.toIso8601String(),
    };
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
