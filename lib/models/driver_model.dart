import 'location_model.dart';

enum DriverStatus { available, busy, offline }

class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final double rating;
  final int reviewCount;
  final String vehicleType; // 'economy', 'premium', 'comfort'
  final String licensePlate;
  final String vehicleColor;
  final DriverStatus status;
  final Location currentLocation;
  final int eta; // minutes estimées

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.reviewCount,
    required this.vehicleType,
    required this.licensePlate,
    required this.vehicleColor,
    required this.status,
    required this.currentLocation,
    required this.eta,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      rating: json['rating'] as double,
      reviewCount: json['reviewCount'] as int,
      vehicleType: json['vehicleType'] as String,
      licensePlate: json['licensePlate'] as String,
      vehicleColor: json['vehicleColor'] as String,
      status:
          DriverStatus.values.byName(json['status'] as String? ?? 'offline'),
      currentLocation:
          Location.fromJson(json['currentLocation'] as Map<String, dynamic>),
      eta: json['eta'] as int,
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
      'licensePlate': licensePlate,
      'vehicleColor': vehicleColor,
      'status': status.name,
      'currentLocation': currentLocation.toJson(),
      'eta': eta,
    };
  }
}
