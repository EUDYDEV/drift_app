class RoomModel {
  final String id;
  final String name;
  final String priceDisplay;
  final int priceValue;
  final String imageSeed;
  final List<String> gallerySeeds;

  // Compatibility fields used by the "service" flow.
  final String roomType;
  final int capacity;
  final double price;
  final List<String> amenities;
  final bool available;
  final String? image;
  final String? virtualTourUrl;

  RoomModel({
    required this.id,
    required this.name,
    required this.priceDisplay,
    required this.priceValue,
    required this.imageSeed,
    required this.gallerySeeds,
    String? roomType,
    this.capacity = 2,
    double? price,
    this.amenities = const <String>[],
    this.available = true,
    this.image,
    this.virtualTourUrl,
  })  : roomType = roomType ?? name,
        price = price ?? priceValue.toDouble();
}

class Room extends RoomModel {
  Room({
    required super.id,
    required String roomType,
    required super.capacity,
    required double price,
    required super.amenities,
    required super.available,
    super.image,
    super.virtualTourUrl,
  }) : super(
          name: roomType,
          roomType: roomType,
          price: price,
          priceDisplay: '${price.round()} FCFA',
          priceValue: price.round(),
          imageSeed: image ?? '',
          gallerySeeds: image != null ? <String>[image] : const <String>[],
        );

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      roomType: json['roomType'] as String,
      capacity: json['capacity'] as int,
      price: (json['price'] as num).toDouble(),
      amenities: List<String>.from(json['amenities'] as List),
      available: json['available'] as bool,
      image: json['image'] as String?,
      virtualTourUrl: json['virtualTourUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomType': roomType,
      'capacity': capacity,
      'price': price,
      'amenities': amenities,
      'available': available,
      'image': image,
      'virtualTourUrl': virtualTourUrl,
    };
  }
}
