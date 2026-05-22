import 'location_model.dart';
import 'ride_model.dart';

enum ReservationStatus { pending, confirmed, cancelled, completed }

class Reservation {
  final String id;
  final Location destinationCity;
  final DateTime departureDate;
  final DateTime? returnDate; // nullable pour trajet aller simple
  final double totalPrice;
  final ReservationStatus status;
  final List<String> hotelIds; // IDs des hôtels sélectionnés
  final List<String> roomIds; // IDs des chambres sélectionnées
  final Ride? departureTour;
  final Ride? returnTour;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.destinationCity,
    required this.departureDate,
    this.returnDate,
    required this.totalPrice,
    required this.status,
    required this.hotelIds,
    required this.roomIds,
    this.departureTour,
    this.returnTour,
    required this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      destinationCity:
          Location.fromJson(json['destinationCity'] as Map<String, dynamic>),
      departureDate: DateTime.parse(json['departureDate'] as String),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'] as String)
          : null,
      totalPrice: json['totalPrice'] as double,
      status: ReservationStatus.values.byName(json['status'] as String),
      hotelIds: List<String>.from(json['hotelIds'] as List),
      roomIds: List<String>.from(json['roomIds'] as List),
      departureTour: json['departureTour'] != null
          ? Ride.fromJson(json['departureTour'] as Map<String, dynamic>)
          : null,
      returnTour: json['returnTour'] != null
          ? Ride.fromJson(json['returnTour'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinationCity': destinationCity.toJson(),
      'departureDate': departureDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status.name,
      'hotelIds': hotelIds,
      'roomIds': roomIds,
      'departureTour': departureTour?.toJson(),
      'returnTour': returnTour?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
