import 'package:flutter/material.dart';
import '../models/ride_option_model.dart';
import '../models/location_model.dart';

class RideService extends ChangeNotifier {
  List<RideOption> _availableOptions = [];
  bool _isLoading = false;
  String? _error;

  List<RideOption> get availableOptions => _availableOptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Récupère les options de trajet disponibles
  Future<List<RideOption>> getRideOptions({
    required Location from,
    required Location to,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulation: calcule la distance et propose des prix
      final distance = from.distanceTo(to);
      final estimatedMinutes = (distance * 3).toInt(); // ~20 km/h

      _availableOptions = [
        RideOption(
          type: RideType.withDriver,
          label: "Avec chauffeur",
          price: (distance * 2.5).toDouble(),
          estimatedPrice: (distance * 2.5).toDouble(),
          estimatedTime: "$estimatedMinutes-${estimatedMinutes + 5} min",
          vehicleType: "comfort",
          description: "Chauffeur professionnel pour plus de confort",
        ),
        RideOption(
          type: RideType.withoutDriver,
          label: "Sans chauffeur",
          price: (distance * 1.8).toDouble(),
          estimatedPrice: (distance * 1.8).toDouble(),
          estimatedTime: "$estimatedMinutes-${estimatedMinutes + 5} min",
          vehicleType: "economy",
          description: "Conduisez vous-même - option économique",
        ),
      ];

      _error = null;
      notifyListeners();
      return _availableOptions;
    } catch (e) {
      _error = "Erreur lors de la récupération des options: $e";
      notifyListeners();
      return [];
    }
  }

  /// Estime la durée d'un trajet
  Future<String> estimateTravelTime(Location from, Location to) async {
    try {
      final distance = from.distanceTo(to);
      final minutes = (distance * 3).toInt();
      return "$minutes min";
    } catch (e) {
      return "N/A";
    }
  }

  /// Calcule le prix d'un trajet
  Future<double> calculatePrice({
    required Location from,
    required Location to,
    required RideType rideType,
  }) async {
    try {
      final distance = from.distanceTo(to);
      const baseFare = 1000.0; // 1000 FCFA
      final perKmRate = rideType == RideType.withDriver ? 2.5 : 1.8;
      return baseFare + (distance * perKmRate);
    } catch (e) {
      return 0;
    }
  }
}
