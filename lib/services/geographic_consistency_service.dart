import 'package:flutter/material.dart';

import '../models/cart_model.dart';
import '../models/location_model.dart';
import 'location_service.dart';

enum _GeoDialogAction {
  dismiss,
  recommendHotel,
}

class GeographicConsistencyAlertContext {
  final CartItem item;
  final AppLocation referenceLocation;
  final AppLocation partnerLocation;
  final String currentCity;
  final String partnerCity;

  const GeographicConsistencyAlertContext({
    required this.item,
    required this.referenceLocation,
    required this.partnerLocation,
    required this.currentCity,
    required this.partnerCity,
  });
}

class GeographicConsistencyService {
  GeographicConsistencyService({
    required LocationService locationService,
  }) : _locationService = locationService;

  final LocationService _locationService;

  Future<bool> showAlertIfNeeded({
    required BuildContext context,
    required String? partnerCityHint,
    required double? partnerLatitude,
    required double? partnerLongitude,
    String? partnerAddress,
    required VoidCallback onNeedHotelSuggestions,
  }) async {
    final currentLocation = await _locationService.getCurrentLocation();
    if (currentLocation == null) return false;

    final partnerLocation = await _resolvePartnerLocation(
      partnerCityHint: partnerCityHint,
      partnerLatitude: partnerLatitude,
      partnerLongitude: partnerLongitude,
      partnerAddress: partnerAddress,
    );

    if (partnerLocation == null) return false;

    final distanceKm = currentLocation.distanceTo(partnerLocation);
    if (distanceKm <= 50) {
      return false;
    }

    if (!context.mounted) {
      return true;
    }

    final currentCity =
        _labelFromLocation(currentLocation, fallback: 'Abidjan');
    final partnerCity = _labelFromLocation(
      partnerLocation,
      fallback: partnerCityHint ?? 'la ville de votre prestation',
    );

    final action = await _showAlertDialog(
      context: context,
      currentCity: currentCity,
      partnerCity: partnerCity,
    );

    if (action == _GeoDialogAction.recommendHotel) {
      onNeedHotelSuggestions();
    }

    return true;
  }

  Future<GeographicConsistencyAlertContext?> showAlertForPackIfNeeded({
    required BuildContext context,
    required Iterable<CartItem> items,
    required VoidCallback onNeedHotelSuggestions,
  }) async {
    final candidate = await findOutlierInPack(items);
    if (candidate == null) {
      return null;
    }

    if (!context.mounted) {
      return candidate;
    }

    final action = await _showAlertDialog(
      context: context,
      currentCity: candidate.currentCity,
      partnerCity: candidate.partnerCity,
    );

    if (action == _GeoDialogAction.recommendHotel) {
      onNeedHotelSuggestions();
    }

    return candidate;
  }

  Future<GeographicConsistencyAlertContext?> findOutlierInPack(
    Iterable<CartItem> items,
  ) async {
    final materialized = items.toList(growable: false);
    if (materialized.isEmpty) {
      return null;
    }

    final referenceLocation = await _resolveReferenceLocation(materialized);
    if (referenceLocation == null) {
      return null;
    }

    for (final item in materialized) {
      final partnerLocation = await _resolvePartnerLocationFromItem(item);
      if (partnerLocation == null) {
        continue;
      }

      final distanceKm = referenceLocation.distanceTo(partnerLocation);
      if (distanceKm <= 50) {
        continue;
      }

      final currentCity =
          _labelFromLocation(referenceLocation, fallback: 'Abidjan');
      final partnerCity = _labelFromLocation(
        partnerLocation,
        fallback: item.partnerCity ?? 'la ville de votre prestation',
      );

      return GeographicConsistencyAlertContext(
        item: item,
        referenceLocation: referenceLocation,
        partnerLocation: partnerLocation,
        currentCity: currentCity,
        partnerCity: partnerCity,
      );
    }

    return null;
  }

  Future<AppLocation?> _resolveReferenceLocation(List<CartItem> items) async {
    for (final item in items) {
      final metadataLocation =
          _locationFromDynamic(item.metadata['pickupLocation']);
      if (metadataLocation != null) {
        return metadataLocation;
      }
    }

    return _locationService.getCurrentLocation();
  }

  Future<AppLocation?> _resolvePartnerLocationFromItem(CartItem item) async {
    return _resolvePartnerLocation(
      partnerCityHint: item.partnerCity,
      partnerLatitude: item.partnerLatitude,
      partnerLongitude: item.partnerLongitude,
      partnerAddress: item.partnerAddress,
    );
  }

  Future<AppLocation?> _resolvePartnerLocation({
    required String? partnerCityHint,
    required double? partnerLatitude,
    required double? partnerLongitude,
    required String? partnerAddress,
  }) async {
    if (partnerLatitude != null && partnerLongitude != null) {
      return _locationService.getLocationFromCoordinates(
        partnerLatitude,
        partnerLongitude,
        fallbackAddress: partnerAddress ?? 'Destination partenaire',
      );
    }

    if (partnerAddress != null && partnerAddress.trim().isNotEmpty) {
      final fromAddress =
          await _locationService.getCoordinatesFromAddress(partnerAddress);
      if (fromAddress != null) {
        return AppLocation(
          latitude: fromAddress.latitude,
          longitude: fromAddress.longitude,
          address: fromAddress.address,
          city: partnerCityHint ?? fromAddress.city,
          country: fromAddress.country,
        );
      }
    }

    if (partnerCityHint != null && partnerCityHint.trim().isNotEmpty) {
      return _locationService.getCoordinatesFromAddress(partnerCityHint);
    }

    return null;
  }

  Future<_GeoDialogAction?> _showAlertDialog({
    required BuildContext context,
    required String currentCity,
    required String partnerCity,
  }) {
    return showDialog<_GeoDialogAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alerte de coherence'),
          content: Text(
            'Nous remarquons que vous reservez a $partnerCity alors que vous etes a $currentCity. '
            'Avez-vous pense a votre hebergement ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_GeoDialogAction.dismiss);
              },
              child: const Text('Oui, je sais ou dormir'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(_GeoDialogAction.recommendHotel);
              },
              child: const Text('Non, proposez-moi'),
            ),
          ],
        );
      },
    );
  }

  AppLocation? _locationFromDynamic(dynamic raw) {
    if (raw is AppLocation) {
      return raw;
    }

    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      return AppLocation.fromJson(map);
    }

    return null;
  }

  String _labelFromLocation(AppLocation location, {required String fallback}) {
    if (location.city != null && location.city!.trim().isNotEmpty) {
      return location.city!;
    }

    if (location.address.trim().isNotEmpty) {
      final segments = location.address
          .split(',')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }

    return fallback;
  }
}
