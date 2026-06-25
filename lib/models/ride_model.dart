import 'driver_model.dart';
import 'location_model.dart';
import 'ride_option_model.dart';

enum RideStatus {
  pending,
  requested,
  accepted,
  scheduled,
  inProgress,
  overtime,
  completed,
  cancelled,
  restricted,
}

enum RideScheduleType { immediate, scheduled }

enum RideGroupContext { soloBusiness, couple, family, group }

enum RidePaymentStatus { included, charged, failed, pending }

class Ride {
  final String id;
  final String? driverId;
  final AppLocation pickupLocation;
  final AppLocation destinationLocation;
  final RideType rideType;
  final RideScheduleType scheduleType;
  final RideGroupContext groupContext;
  final RideStatus status;
  final RidePaymentStatus paymentStatus;
  final Driver? driver;
  final String origin;
  final String destination;
  final int passengerCount;
  final int requestedDurationMinutes;
  final String vehicleType;
  final int seatCapacity;
  final double price;
  final double estimatedPrice;
  final double hourlyRate;
  final double overtimeAmount;
  final double finalAmount;
  final double penaltyAmount;
  final int overtimeMinutes;
  final String estimatedTime;
  final String? restrictionReason;
  final DateTime createdAt;
  final DateTime? scheduledStart;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final DateTime? autoChargeAttemptedAt;

  const Ride({
    required this.id,
    required this.driverId,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.rideType,
    required this.scheduleType,
    required this.groupContext,
    required this.status,
    required this.paymentStatus,
    this.driver,
    required this.origin,
    required this.destination,
    required this.passengerCount,
    required this.requestedDurationMinutes,
    required this.vehicleType,
    required this.seatCapacity,
    required this.price,
    required this.estimatedPrice,
    required this.hourlyRate,
    required this.overtimeAmount,
    required this.finalAmount,
    required this.penaltyAmount,
    required this.overtimeMinutes,
    required this.estimatedTime,
    this.restrictionReason,
    required this.createdAt,
    this.scheduledStart,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
    this.autoChargeAttemptedAt,
  });

  bool get isTerminal =>
      status == RideStatus.completed ||
      status == RideStatus.cancelled ||
      status == RideStatus.restricted;

  bool get isOvertime => status == RideStatus.overtime;

  bool get isRestricted => status == RideStatus.restricted;

  factory Ride.fromJson(Map<String, dynamic> json) {
    final pickupLocation = _locationValue(
      json['pickupLocation'],
      fallbackAddress: json['origin'] as String? ?? 'Origine inconnue',
    );
    final destinationLocation = _locationValue(
      json['destinationLocation'],
      fallbackAddress: json['destination'] as String? ?? 'Destination inconnue',
    );

    final estimatedPrice = _doubleValue(json, 'estimatedPrice', fallbackKey: 'price');
    final finalAmount =
        _doubleValue(json, 'finalAmount', fallback: estimatedPrice);
    final overtimeAmount =
        _doubleValue(json, 'overtimeAmount', fallback: 0);
    final penaltyAmount = _doubleValue(json, 'penaltyAmount', fallback: 0);

    return Ride(
      id: json['id']?.toString() ?? '',
      driverId: json['driverId']?.toString(),
      pickupLocation: pickupLocation,
      destinationLocation: destinationLocation,
      rideType: _rideTypeValue(json['rideType'] as String?),
      scheduleType: _scheduleTypeValue(json['scheduleType'] as String?),
      groupContext: _groupContextValue(json['groupContext'] as String?),
      status: _rideStatusValue(json['status'] as String?),
      paymentStatus: _paymentStatusValue(json['paymentStatus'] as String?),
      driver: json['driver'] is Map<String, dynamic>
          ? Driver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      origin: json['origin'] as String? ?? pickupLocation.address,
      destination: json['destination'] as String? ?? destinationLocation.address,
      passengerCount: _intValue(json, 'passengerCount', fallback: 1),
      requestedDurationMinutes:
          _intValue(json, 'requestedDurationMinutes', fallback: 60),
      vehicleType: json['vehicleType'] as String? ?? 'comfort',
      seatCapacity: _intValue(json, 'seatCapacity', fallback: 4),
      price: finalAmount > 0 ? finalAmount : estimatedPrice,
      estimatedPrice: estimatedPrice,
      hourlyRate: _doubleValue(json, 'hourlyRate', fallback: 0),
      overtimeAmount: overtimeAmount,
      finalAmount: finalAmount,
      penaltyAmount: penaltyAmount,
      overtimeMinutes: _intValue(json, 'overtimeMinutes', fallback: 0),
      estimatedTime:
          json['estimatedTimeText'] as String? ??
          json['estimatedTime'] as String? ??
          '',
      restrictionReason: json['restrictionReason'] as String?,
      createdAt: _dateValue(json['createdAt']) ?? DateTime.now(),
      scheduledStart: _dateValue(json['scheduledStart']),
      startedAt: _dateValue(json['startedAt']),
      completedAt: _dateValue(json['completedAt']),
      updatedAt: _dateValue(json['updatedAt']),
      autoChargeAttemptedAt: _dateValue(json['autoChargeAttemptedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'pickupLocation': pickupLocation.toJson(),
      'destinationLocation': destinationLocation.toJson(),
      'rideType': rideType.name,
      'scheduleType': scheduleType.name,
      'groupContext': groupContext.name,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'driver': driver?.toJson(),
      'origin': origin,
      'destination': destination,
      'passengerCount': passengerCount,
      'requestedDurationMinutes': requestedDurationMinutes,
      'vehicleType': vehicleType,
      'seatCapacity': seatCapacity,
      'price': price,
      'estimatedPrice': estimatedPrice,
      'hourlyRate': hourlyRate,
      'overtimeAmount': overtimeAmount,
      'finalAmount': finalAmount,
      'penaltyAmount': penaltyAmount,
      'overtimeMinutes': overtimeMinutes,
      'estimatedTimeText': estimatedTime,
      'restrictionReason': restrictionReason,
      'createdAt': createdAt.toIso8601String(),
      'scheduledStart': scheduledStart?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'autoChargeAttemptedAt': autoChargeAttemptedAt?.toIso8601String(),
    };
  }
}

class RideSettlementResult {
  final Ride ride;
  final bool userRestricted;
  final String? restrictionReason;
  final String? infractionId;

  const RideSettlementResult({
    required this.ride,
    required this.userRestricted,
    this.restrictionReason,
    this.infractionId,
  });

  factory RideSettlementResult.fromJson(Map<String, dynamic> json) {
    return RideSettlementResult(
      ride: Ride.fromJson(
        (json['ride'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      userRestricted: json['userRestricted'] as bool? ?? false,
      restrictionReason: json['restrictionReason'] as String?,
      infractionId: json['infractionId']?.toString(),
    );
  }
}

RideType _rideTypeValue(String? raw) {
  return raw == 'withoutDriver' ? RideType.withoutDriver : RideType.withDriver;
}

RideScheduleType _scheduleTypeValue(String? raw) {
  return raw == 'scheduled'
      ? RideScheduleType.scheduled
      : RideScheduleType.immediate;
}

RideGroupContext _groupContextValue(String? raw) {
  switch (raw) {
    case 'couple':
      return RideGroupContext.couple;
    case 'family':
      return RideGroupContext.family;
    case 'group':
      return RideGroupContext.group;
    default:
      return RideGroupContext.soloBusiness;
  }
}

RideStatus _rideStatusValue(String? raw) {
  switch (raw) {
    case 'requested':
      return RideStatus.requested;
    case 'accepted':
      return RideStatus.accepted;
    case 'scheduled':
      return RideStatus.scheduled;
    case 'inProgress':
      return RideStatus.inProgress;
    case 'overtime':
      return RideStatus.overtime;
    case 'completed':
      return RideStatus.completed;
    case 'cancelled':
      return RideStatus.cancelled;
    case 'restricted':
      return RideStatus.restricted;
    default:
      return RideStatus.pending;
  }
}

RidePaymentStatus _paymentStatusValue(String? raw) {
  switch (raw) {
    case 'charged':
      return RidePaymentStatus.charged;
    case 'failed':
      return RidePaymentStatus.failed;
    case 'pending':
      return RidePaymentStatus.pending;
    default:
      return RidePaymentStatus.included;
  }
}

AppLocation _locationValue(dynamic raw, {required String fallbackAddress}) {
  if (raw is Map<String, dynamic>) {
    return AppLocation.fromJson(raw);
  }

  return AppLocation(
    latitude: 0,
    longitude: 0,
    address: fallbackAddress,
    city: 'Abidjan',
    country: "Cote d'Ivoire",
  );
}

double _doubleValue(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
  double fallback = 0,
}) {
  final direct = json[key];
  if (direct is num) return direct.toDouble();

  if (fallbackKey != null) {
    final alternate = json[fallbackKey];
    if (alternate is num) return alternate.toDouble();
  }

  return fallback;
}

int _intValue(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is num) return value.toInt();
  return fallback;
}

DateTime? _dateValue(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
