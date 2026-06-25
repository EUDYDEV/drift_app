import 'location_model.dart';
import 'ride_model.dart';

enum ReservationStatus { pending, confirmed, cancelled, completed }

class Reservation {
  final String id;
  final String? userId;
  final String? hotelId;
  final String? roomId;
  final AppLocation destinationCity;
  final DateTime departureDate;
  final DateTime? returnDate;
  final double totalPrice;
  final int capacity;
  final ReservationStatus status;
  final List<String> hotelIds;
  final List<String> roomIds;
  final Ride? departureTour;
  final Ride? returnTour;
  final DateTime createdAt;

  Reservation({
    required this.id,
    this.userId,
    this.hotelId,
    this.roomId,
    required this.destinationCity,
    required this.departureDate,
    this.returnDate,
    required this.totalPrice,
    this.capacity = 1,
    required this.status,
    required this.hotelIds,
    required this.roomIds,
    this.departureTour,
    this.returnTour,
    required this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final hotelId = json['hotelId']?.toString() ?? json['hotel_id']?.toString();
    final roomId = json['roomId']?.toString() ?? json['room_id']?.toString();

    return Reservation(
      id: json['id'].toString(),
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      hotelId: hotelId,
      roomId: roomId,
      destinationCity: _readLocation(json),
      departureDate: DateTime.parse(
        (json['departureDate'] ??
                json['startDate'] ??
                json['start_date'] ??
                DateTime.now().toIso8601String())
            .toString(),
      ),
      returnDate: _readOptionalDate(
        json['returnDate'] ?? json['endDate'] ?? json['end_date'],
      ),
      totalPrice: _readDouble(json['totalPrice'] ?? json['price']),
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      status: _readStatus(json['status']?.toString()),
      hotelIds: _mergeIds(
        json['hotelIds'] ?? json['hotel_ids'],
        hotelId,
      ),
      roomIds: _mergeIds(
        json['roomIds'] ?? json['room_ids'],
        roomId,
      ),
      departureTour: json['departureTour'] is Map<String, dynamic>
          ? Ride.fromJson(json['departureTour'] as Map<String, dynamic>)
          : null,
      returnTour: json['returnTour'] is Map<String, dynamic>
          ? Ride.fromJson(json['returnTour'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(
        (json['createdAt'] ??
                json['created_at'] ??
                DateTime.now().toIso8601String())
            .toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'hotelId': hotelId,
      'roomId': roomId,
      'destinationCity': destinationCity.toJson(),
      'departureDate': departureDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'totalPrice': totalPrice,
      'capacity': capacity,
      'status': status.name,
      'hotelIds': hotelIds,
      'roomIds': roomIds,
      'departureTour': departureTour?.toJson(),
      'returnTour': returnTour?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static AppLocation _readLocation(Map<String, dynamic> json) {
    final dynamic location = json['destinationCity'];
    if (location is Map<String, dynamic>) {
      return AppLocation.fromJson(location);
    }

    final address = (json['address'] ?? json['city'] ?? '').toString();
    return AppLocation(
      latitude: 0,
      longitude: 0,
      address: address,
      city: address.isEmpty ? null : address,
    );
  }

  static DateTime? _readOptionalDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static ReservationStatus _readStatus(String? raw) {
    switch (raw) {
      case 'pending':
        return ReservationStatus.pending;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'completed':
        return ReservationStatus.completed;
      default:
        return ReservationStatus.confirmed;
    }
  }

  static List<String> _mergeIds(dynamic raw, String? singleValue) {
    final values = <String>[];
    if (raw is List) {
      values.addAll(raw.map((item) => item.toString()));
    }
    if (singleValue != null && singleValue.isNotEmpty && !values.contains(singleValue)) {
      values.add(singleValue);
    }
    return values;
  }

  static double _readDouble(dynamic raw) {
    return (raw as num?)?.toDouble() ?? 0;
  }
}
