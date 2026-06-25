import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/driver_model.dart';
import '../models/location_model.dart';
import '../models/ride_model.dart';
import '../models/ride_request_details.dart';
import 'api_service.dart';

class DriverAvailabilityService extends ChangeNotifier {
  List<Driver> _nearbyDrivers = [];
  bool _isSearching = false;
  String? _error;

  List<Driver> get nearbyDrivers => _nearbyDrivers;
  bool get isSearching => _isSearching;
  String? get error => _error;

  Future<List<Driver>> findNearbyDrivers({
    required AppLocation location,
    required double radiusKm,
  }) async {
    final _ = location;
    final __ = radiusKm;
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.authenticatedGet('/rides/nearby-drivers');

      if (response.statusCode != 200) {
        throw Exception(_extractError(
          response.body,
          fallback: 'Impossible de recuperer les chauffeurs disponibles.',
        ));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('La reponse des chauffeurs est invalide.');
      }

      _nearbyDrivers = decoded
          .whereType<Map<String, dynamic>>()
          .map(Driver.fromJson)
          .toList();

      return _nearbyDrivers;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<Ride> acceptRideWithDriver({
    required Driver driver,
    required RideRequestDetails request,
  }) async {
    final response = await ApiService.authenticatedPost(
      '/rides',
      request.toJson(driverId: driver.id),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Session utilisateur introuvable.');
    }

    if (response.statusCode != 201) {
      throw Exception(_extractError(
        response.body,
        fallback: 'La course n\'a pas pu etre creee.',
      ));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La reponse de creation de course est invalide.');
    }

    return Ride.fromJson(decoded);
  }

  Future<Ride> getRideById(String rideId) async {
    final response = await ApiService.authenticatedGet('/rides/$rideId');
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Session utilisateur introuvable.');
    }
    if (response.statusCode != 200) {
      throw Exception(_extractError(
        response.body,
        fallback: 'Impossible de recuperer cette course.',
      ));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La reponse de course est invalide.');
    }

    return Ride.fromJson(decoded);
  }

  Future<Ride> cancelRide(String rideId) async {
    final response = await ApiService.authenticatedPost(
      '/rides/$rideId/cancel',
      const <String, dynamic>{},
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Session utilisateur introuvable.');
    }

    if (response.statusCode != 200) {
      throw Exception(_extractError(
        response.body,
        fallback: 'Impossible d\'annuler la course.',
      ));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La reponse d\'annulation est invalide.');
    }

    return Ride.fromJson(decoded);
  }

  Future<RideSettlementResult> completeRide(String rideId) async {
    final response = await ApiService.authenticatedPost(
      '/rides/$rideId/complete',
      const <String, dynamic>{},
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Session utilisateur introuvable.');
    }

    if (response.statusCode != 200) {
      throw Exception(_extractError(
        response.body,
        fallback: 'Impossible de cloturer la course.',
      ));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La reponse de cloture est invalide.');
    }

    return RideSettlementResult.fromJson(decoded);
  }

  String _extractError(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.isNotEmpty) {
          return error;
        }
      }
    } catch (_) {
      // Ignore body parsing and fall back to the provided message.
    }

    return fallback;
  }
}
