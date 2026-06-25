import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';

class LocationService extends ChangeNotifier {
  AppLocation? _currentLocation;
  AppLocation? get currentLocation => _currentLocation;

  StreamSubscription<Position>? _positionSubscription;

  /// Vérifie les permissions et récupère la position actuelle
  Future<AppLocation?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Vérifier si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Le service de localisation est désactivé.');
    }

    // 2. Vérifier les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Les permissions de localisation sont refusées.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Les permissions sont définitivement refusées.');
    }

    // 3. Récupérer la position
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 4. Convertir en adresse lisible (Reverse Geocoding)
      String address = "Position actuelle";
      String? city;
      String? country;
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          geo.Placemark place = placemarks[0];
          address = "${place.street}, ${place.locality}";
          city = place.locality ?? place.subAdministrativeArea;
          country = place.country;
        }
      } catch (e) {
        debugPrint("Erreur geocoding: $e");
      }

      _currentLocation = AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
        country: country,
      );

      notifyListeners();
      return _currentLocation;
    } catch (e) {
      debugPrint("Erreur GPS: $e");
      return null;
    }
  }

  /// Démarre l'écoute continue de la position
  void startLocationListener() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10 mètres
      ),
    ).listen((position) async {
      String address = "Position actuelle";
      String? city;
      String? country;
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          geo.Placemark place = placemarks[0];
          address = "${place.street}, ${place.locality}";
          city = place.locality ?? place.subAdministrativeArea;
          country = place.country;
        }
      } catch (e) {
        debugPrint("Erreur geocoding stream: $e");
      }

      _currentLocation = AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
        country: country,
      );
      notifyListeners();
    });
  }

  /// Arrête l'écoute continue de la position
  void stopLocationListener() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Récupère les coordonnées d'une adresse texte
  Future<AppLocation?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await geo.locationFromAddress(address);
      if (locations.isEmpty) return null;

      final geo.Location loc = locations.first;
      return AppLocation(
        latitude: loc.latitude,
        longitude: loc.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint("Erreur geocoding adresse: $e");
      return null;
    }
  }

  Future<void> saveLocationForLater(AppLocation location) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'drift_saved_location',
      '${location.latitude}|${location.longitude}|${location.address}',
    );
  }

  Future<void> shareLocation(AppLocation location) async {
    final deepLink =
        'driftapp://location?lat=${location.latitude}&lon=${location.longitude}'
        '&address=${Uri.encodeComponent(location.address)}';
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Partage de position',
        text: 'Ma position : ${location.address}\n\n$deepLink',
      ),
    );
  }

  Future<AppLocation?> getLocationFromCoordinates(
    double latitude,
    double longitude, {
    String fallbackAddress = 'Destination partenaire',
  }) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return AppLocation(
          latitude: latitude,
          longitude: longitude,
          address: fallbackAddress,
        );
      }

      final place = placemarks.first;
      final address = [
        place.street,
        place.locality,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

      return AppLocation(
        latitude: latitude,
        longitude: longitude,
        address: address.isEmpty ? fallbackAddress : address,
        city: place.locality ?? place.subAdministrativeArea,
        country: place.country,
      );
    } catch (e) {
      debugPrint('Erreur geocoding coords: $e');
      return AppLocation(
        latitude: latitude,
        longitude: longitude,
        address: fallbackAddress,
      );
    }
  }

  /// Stream pour écouter les déplacements en temps réel
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10 mètres
      ),
    );
  }

  @override
  void dispose() {
    stopLocationListener();
    super.dispose();
  }
}
