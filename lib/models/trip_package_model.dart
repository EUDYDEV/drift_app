import 'ride_model.dart';

class TripPackage {
  final String id;
  final List<Ride> rides; // trajets réservés
  final List<HotelBooking> hotelBookings; // hôtels réservés
  final double totalPrice;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  TripPackage({
    required this.id,
    required this.rides,
    required this.hotelBookings,
    required this.totalPrice,
    required this.createdAt,
    this.confirmedAt,
  });
}

class HotelBooking {
  final String hotelId;
  final String hotelName;
  final String roomId;
  final String roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final double price;

  HotelBooking({
    required this.hotelId,
    required this.hotelName,
    required this.roomId,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.price,
  });
}
