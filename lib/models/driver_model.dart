import 'location_model.dart';

enum DriverStatus { available, busy, offline }

class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final double rating;
  final int reviewCount;
  final String vehicleType;
  final double price;
  final int capacity;
  final String licensePlate;
  final String vehicleColor;
  final DriverStatus status;
  final AppLocation currentLocation;
  final int eta;
  final DateTime? createdAt;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.reviewCount,
    required this.vehicleType,
    this.price = 0,
    this.capacity = 4,
    required this.licensePlate,
    required this.vehicleColor,
    required this.status,
    required this.currentLocation,
    required this.eta,
    this.createdAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Chauffeur',
      phoneNumber:
          (json['phoneNumber'] ?? json['phone_number']) as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount:
          ((json['reviewCount'] ?? json['review_count']) as num?)?.toInt() ?? 0,
      vehicleType:
          (json['vehicleType'] ?? json['vehicle_type']) as String? ??
              'economy',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      licensePlate:
          (json['licensePlate'] ?? json['license_plate']) as String? ?? '',
      vehicleColor:
          (json['vehicleColor'] ?? json['vehicle_color']) as String? ?? '',
      status: _statusFromString(json['status'] as String?),
      currentLocation: AppLocation.fromJson(
        ((json['currentLocation'] ?? json['current_location'])
                as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      eta: (json['eta'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'rating': rating,
      'reviewCount': reviewCount,
      'vehicleType': vehicleType,
      'price': price,
      'capacity': capacity,
      'licensePlate': licensePlate,
      'vehicleColor': vehicleColor,
      'status': status.name,
      'currentLocation': currentLocation.toJson(),
      'eta': eta,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DriverStatus _statusFromString(String? raw) {
    switch (raw) {
      case 'available':
        return DriverStatus.available;
      case 'busy':
        return DriverStatus.busy;
      default:
        return DriverStatus.offline;
    }
  }
}
