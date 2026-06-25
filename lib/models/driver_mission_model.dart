import 'ride_model.dart';

class MissionVehicle {
  final String id;
  final String name;
  final String vehicleType;
  final String registrationNumber;
  final String color;
  final int capacity;

  const MissionVehicle({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.registrationNumber,
    required this.color,
    required this.capacity,
  });

  factory MissionVehicle.fromJson(Map<String, dynamic> json) {
    return MissionVehicle(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Vehicule Drift',
      vehicleType: json['vehicleType'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      color: json['color'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverMission {
  final Ride ride;
  final String companyName;
  final MissionVehicle? vehicle;

  const DriverMission({
    required this.ride,
    required this.companyName,
    this.vehicle,
  });

  factory DriverMission.fromJson(Map<String, dynamic> json) {
    final rideJson = json['ride'];
    if (rideJson is! Map) {
      throw const FormatException('Mission chauffeur invalide.');
    }

    final vehicleJson = json['vehicle'];
    return DriverMission(
      ride: Ride.fromJson(
        rideJson.map((key, value) => MapEntry('$key', value)),
      ),
      companyName: json['companyName'] as String? ?? 'Drift',
      vehicle: vehicleJson is Map
          ? MissionVehicle.fromJson(
              vehicleJson.map((key, value) => MapEntry('$key', value)),
            )
          : null,
    );
  }
}
