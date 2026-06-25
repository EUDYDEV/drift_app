import 'dart:math' as math;

import 'location_model.dart';
import 'ride_model.dart';
import 'ride_option_model.dart';

class RideRequestDetails {
  final AppLocation pickupLocation;
  final AppLocation destinationLocation;
  final RideType rideType;
  final RideScheduleType scheduleType;
  final DateTime? scheduledStart;
  final RideGroupContext groupContext;
  final int passengerCount;
  final int requestedDurationMinutes;
  final String vehicleType;
  final int seatCapacity;
  final double quotedPrice;
  final double hourlyRate;
  final double estimatedPrice;
  final String estimatedTimeText;

  const RideRequestDetails({
    required this.pickupLocation,
    required this.destinationLocation,
    required this.rideType,
    required this.scheduleType,
    required this.scheduledStart,
    required this.groupContext,
    required this.passengerCount,
    required this.requestedDurationMinutes,
    required this.vehicleType,
    required this.seatCapacity,
    required this.quotedPrice,
    required this.hourlyRate,
    required this.estimatedPrice,
    required this.estimatedTimeText,
  });

  bool get requiresMiniCar =>
      groupContext == RideGroupContext.group && passengerCount >= 10;

  factory RideRequestDetails.fromSelections({
    required AppLocation pickupLocation,
    required AppLocation destinationLocation,
    required RideOption selectedOption,
    required RideScheduleType scheduleType,
    required DateTime? scheduledStart,
    required RideGroupContext groupContext,
    required int passengerCount,
    required int requestedDurationMinutes,
  }) {
    final safePassengerCount = math.max(1, passengerCount);
    final safeDurationMinutes = math.max(30, requestedDurationMinutes);
    final requiresMiniCar =
        groupContext == RideGroupContext.group && safePassengerCount >= 10;
    final requestedVehicleType =
        selectedOption.vehicleType.trim().toLowerCase();
    final resolvedVehicleType =
        requiresMiniCar ? 'mini-car' : requestedVehicleType;
    final seatCapacity = requiresMiniCar ? 30 : 4;

    final baseRate = switch (resolvedVehicleType) {
      'economy' => 12000.0,
      'premium' => 25000.0,
      'mini-car' => 45000.0,
      _ => 18000.0,
    };

    final groupMultiplier = switch (groupContext) {
      RideGroupContext.couple => 1.10,
      RideGroupContext.family => 1.25,
      RideGroupContext.group => requiresMiniCar ? 1.0 : 1.45,
      RideGroupContext.soloBusiness => 1.0,
    };

    final hourlyRate = requiresMiniCar
        ? math.max(selectedOption.price, 45000.0)
        : math.max(selectedOption.price, baseRate * groupMultiplier);

    final estimatedPrice =
        ((safeDurationMinutes / 60.0) * hourlyRate).ceilToDouble();

    return RideRequestDetails(
      pickupLocation: pickupLocation,
      destinationLocation: destinationLocation,
      rideType: selectedOption.type,
      scheduleType: scheduleType,
      scheduledStart: scheduleType == RideScheduleType.scheduled
          ? scheduledStart
          : null,
      groupContext: groupContext,
      passengerCount: safePassengerCount,
      requestedDurationMinutes: safeDurationMinutes,
      vehicleType: resolvedVehicleType,
      seatCapacity: seatCapacity,
      quotedPrice: selectedOption.price,
      hourlyRate: hourlyRate,
      estimatedPrice: estimatedPrice,
      estimatedTimeText: selectedOption.estimatedTime,
    );
  }

  Map<String, dynamic> toJson({String? driverId}) {
    return {
      if (driverId != null) 'driverId': driverId,
      'pickupLocation': pickupLocation.toJson(),
      'destinationLocation': destinationLocation.toJson(),
      'rideType': rideType.name,
      'scheduleType': scheduleType.name,
      'scheduledStart': scheduledStart?.toIso8601String(),
      'groupContext': groupContext.name,
      'passengerCount': passengerCount,
      'requestedDurationMinutes': requestedDurationMinutes,
      'vehicleType': vehicleType,
      'seatCapacity': seatCapacity,
      'quotedPrice': quotedPrice,
      'estimatedTimeText': estimatedTimeText,
    };
  }
}
