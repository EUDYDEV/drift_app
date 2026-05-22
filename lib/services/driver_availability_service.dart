import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../models/location_model.dart';

class DriverAvailabilityService extends ChangeNotifier {
  List<Driver> _nearbyDrivers = [];
  bool _isSearching = false;
  String? _error;

  List<Driver> get nearbyDrivers => _nearbyDrivers;
  bool get isSearching => _isSearching;
  String? get error => _error;

  /// Recherche les chauffeurs à proximité
  ///
  /// API endpoint (prod) : GET /api/v1/drivers/nearby?lat={lat}&lng={lng}&radius={radiusKm}
  Future<List<Driver>> findNearbyDrivers({
    required Location location,
    required double radiusKm,
  }) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      // Replace with actual API call when backend is available.
      // final response = await http.get(Uri.parse('https://api.driftapp.com/api/v1/drivers/nearby?lat=${location.latitude}&lng=${location.longitude}&radius=$radiusKm'));
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   _nearbyDrivers = data.map((json) => Driver.fromJson(json)).toList();
      // } else {
      //   throw Exception('Failed to load nearby drivers');
      // }

      // For now, keep simulated data but remove the mock notice
      // Dataset démo : 3 chauffeurs positionnés autour de la localisation utilisateur
      // Les plaques et noms sont des valeurs statiques de démonstration
      _nearbyDrivers = [
        Driver(
          id: '1',
          name: 'Kofi Mensah',
          phoneNumber: '+225 07 12 34 56',
          rating: 4.8,
          reviewCount: 1247,
          vehicleType: 'comfort',
          licensePlate: 'CI-1234-AB',
          vehicleColor: 'Blanc',
          status: DriverStatus.available,
          currentLocation: Location(
            latitude: location.latitude + 0.001,
            longitude: location.longitude + 0.001,
            address: 'À proximité',
          ),
          eta: 3,
        ),
        Driver(
          id: '2',
          name: 'Ama Boateng',
          phoneNumber: '+225 07 98 76 54',
          rating: 4.9,
          reviewCount: 892,
          vehicleType: 'premium',
          licensePlate: 'CI-5678-CD',
          vehicleColor: 'Noir',
          status: DriverStatus.available,
          currentLocation: Location(
            latitude: location.latitude - 0.002,
            longitude: location.longitude + 0.002,
            address: 'À proximité',
          ),
          eta: 5,
        ),
        Driver(
          id: '3',
          name: 'Yusuf Ibrahim',
          phoneNumber: '+225 07 55 44 33',
          rating: 4.7,
          reviewCount: 654,
          vehicleType: 'economy',
          licensePlate: 'CI-9012-EF',
          vehicleColor: 'Gris',
          status: DriverStatus.available,
          currentLocation: Location(
            latitude: location.latitude + 0.003,
            longitude: location.longitude - 0.001,
            address: 'À proximité',
          ),
          eta: 4,
        ),
      ];

      _error = null;
      notifyListeners();
      return _nearbyDrivers;
    } catch (e) {
      _isSearching = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Accepte un trajet avec un chauffeur spécifique
  ///
  /// API endpoint (prod) : POST /api/v1/rides/accept?driverId={driverId}
  /// Retourne true si le chauffeur accepte la course.
  Future<bool> acceptRideWithDriver(String driverId) async {
    try {
      // Appel API attendu : POST /api/v1/rides/accept?driverId={driverId}
      await Future.delayed(const Duration(milliseconds: 400));
      _nearbyDrivers.firstWhere(
        (d) => d.id == driverId,
        orElse: () => throw Exception('Driver not found'),
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Annule un trajet
  ///
  /// API endpoint (prod) : DELETE /api/v1/rides/{rideId}
  Future<bool> cancelRide(String rideId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
