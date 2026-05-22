import 'package:flutter/material.dart';
import 'dart:async';
import '../models/location_model.dart';

class LocationService extends ChangeNotifier {
  Location? _currentLocation;
  bool _isListening = false;
  String? _error;
  Timer? _locationTimer;

  Location? get currentLocation => _currentLocation;
  bool get isListening => _isListening;
  String? get error => _error;

  /// Obtient la position actuelle de l'utilisateur
  ///
  /// API endpoint (prod) : GET /api/v1/location/current
  /// Package Flutter recommandé : geolocator
  Future<Location?> getCurrentLocation() async {
    try {
      // En production, appel au backend Rust pour enregistrer la visite
      // await http.get(Uri.parse('https://api.drift.ci/v1/analytics/visit'));

      // Simulation de la récupération GPS réelle (à décommenter avec le package geolocator)
      /* 
      Position position = await Geolocator.getCurrentPosition();
      _currentLocation = Location(latitude: position.latitude, longitude: position.longitude, ...);
      */

      _currentLocation = Location(
        latitude: 5.3364,
        longitude: -4.0269,
        address: "Plateau, Abidjan",
        city: "Abidjan",
        country: "Côte d'Ivoire",
      );
      _error = null;
      notifyListeners();
      return _currentLocation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Écoute en temps réel la position utilisateur
  ///
  /// API endpoint (prod) : WebSocket /api/v1/location/stream
  /// Package Flutter recommandé : geolocator (PositionStream)
  /// En attendant le backend : mise à jour simulée toutes les 5 secondes.
  void startLocationListener() {
    if (_isListening) return;
    _isListening = true;

    // Utilisation d'un Timer périodique pour la simulation (plus propre que la récursion)
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      if (_currentLocation != null) {
        _currentLocation = Location(
          latitude: _currentLocation!.latitude + 0.0001,
          longitude: _currentLocation!.longitude + 0.0001,
          address: _currentLocation!.address,
          city: _currentLocation!.city,
          country: _currentLocation!.country,
        );
        notifyListeners();
      }
    });
  }

  /// Arrête l'écoute de la position
  void stopLocationListener() {
    _isListening = false;
    _locationTimer?.cancel();
    _locationTimer = null;
    notifyListeners();
  }

  /// Recherche une adresse par coordonnées (reverse geocoding)
  ///
  /// API endpoint (prod) : GET /api/v1/location/reverse?lat={lat}&lng={lng}
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      // En prod : appel API reverse-geocoding
      // Replace with actual geolocator call when backend is available.
      // List<Placemark> placemarks = await Geolocator.placemarkFromCoordinates(latitude, longitude);
      // Placemark place = placemarks[0];
      // return '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      return "Adresse à $latitude, $longitude";
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  /// Recherche les coordonnées d'une adresse (geocoding)
  ///
  /// API endpoint (prod) : GET /api/v1/location/geocode?address={address}
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      // En prod : appel API géocodage
      // Replace with actual geolocator call when backend is available.
      // List<Location> locations = await Geolocator.placemarkFromAddress(address);
      // Placemark place = locations[0];
      // return Location(
      //   latitude: place.position.latitude,
      //   longitude: place.position.longitude,
      //   address: address,
      //   city: "Abidjan", // city is fixed in demo mode
      //   country: "Côte d'Ivoire",
      // );

      // For now, keep simulated data but remove the mock notice
      return Location(
        latitude: 5.3364,
        longitude: -4.0269,
        address: address,
        city: "Abidjan",
        country: "Côte d'Ivoire",
      );
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  @override
  void dispose() {
    stopLocationListener();
    super.dispose();
  }
}
