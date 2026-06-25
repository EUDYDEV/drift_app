import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../models/ride_model.dart';
import '../models/ride_option_model.dart';
import 'api_service.dart';

class RideService {
  Future<List<dynamic>> getNearbyDrivers() async {
    try {
      final response = await ApiService.authenticatedGet('/rides/nearby-drivers');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la recuperation des chauffeurs: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMyRides() async {
    try {
      final response = await ApiService.authenticatedGet('/rides');
      if (response.statusCode == 401 || response.statusCode == 403) {
        return [];
      }
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) return [];

        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Ride.fromJson)
            .map((ride) => {
                  'id': ride.id,
                  'title': 'Trajet vers ${ride.destination}',
                  'description':
                      '${_statusLabel(ride.status)} - ${ride.finalAmount.toStringAsFixed(0)} FCFA',
                })
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la recuperation des trajets: $e');
      return [];
    }
  }

  Future<bool> requestRide(String destination, double price) async {
    final _ = price;
    try {
      final response = await ApiService.authenticatedPost(
        '/rides/request',
        {
          'origin': 'Position actuelle',
          'destination': destination,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Erreur lors de la creation de la course: $e');
      return false;
    }
  }

  Future<List<RideOption>> getRideOptions({
    required AppLocation from,
    required AppLocation to,
  }) async {
    final distanceKm = from.distanceTo(to);
    final basePrice = max(1000.0, distanceKm * 500.0);

    return [
      RideOption(
        type: RideType.withDriver,
        label: 'Avec chauffeur',
        price: basePrice * 1.5,
        estimatedPrice: basePrice * 1.5,
        estimatedTime: _formatDuration(distanceKm * 2),
        vehicleType: 'comfort',
        description: 'Chauffeur professionnel, vehicule confortable',
      ),
      RideOption(
        type: RideType.withoutDriver,
        label: 'Sans chauffeur',
        price: basePrice,
        estimatedPrice: basePrice,
        estimatedTime: _formatDuration(distanceKm * 2),
        vehicleType: 'economy',
        description: 'Vehicule autonome, solution economique',
      ),
    ];
  }

  String _formatDuration(double minutes) {
    final min = minutes.round();
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String _statusLabel(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
        return 'Confirmee';
      case RideStatus.scheduled:
        return 'Planifiee';
      case RideStatus.inProgress:
        return 'En cours';
      case RideStatus.overtime:
        return 'Overtime';
      case RideStatus.arrived:
        return 'Arrivee';
      case RideStatus.completed:
        return 'Terminee';
      case RideStatus.cancelled:
        return 'Annulee';
      case RideStatus.restricted:
        return 'Restreinte';
      case RideStatus.pending:
      case RideStatus.requested:
        return 'En attente';
    }
  }

  void dispose() {}
}
