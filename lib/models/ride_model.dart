import 'location_model.dart';
import 'ride_option_model.dart';
import 'driver_model.dart';

enum RideStatus { pending, accepted, inProgress, completed, cancelled }

class Ride {
  final String id;
  final Location pickupLocation;
  final Location destinationLocation;
  final RideType rideType;
  final RideStatus status;
  final Driver? driver;
  final double price;
  final String estimatedTime;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  Ride({
    required this.id,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.rideType,
    required this.status,
    this.driver,
    required this.price,
    required this.estimatedTime,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      pickupLocation:
          Location.fromJson(json['pickupLocation'] as Map<String, dynamic>),
      destinationLocation: Location.fromJson(
          json['destinationLocation'] as Map<String, dynamic>),
      rideType: RideType.values.byName(json['rideType'] as String),
      status: RideStatus.values.byName(json['status'] as String),
      driver: json['driver'] != null
          ? Driver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      price: json['price'] as double,
      estimatedTime: json['estimatedTime'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickupLocation': pickupLocation.toJson(),
      'destinationLocation': destinationLocation.toJson(),
      'rideType': rideType.name,
      'status': status.name,
      'driver': driver?.toJson(),
      'price': price,
      'estimatedTime': estimatedTime,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
