import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/driver_mission_model.dart';
import '../models/location_model.dart';
import 'api_service.dart';

class DriverMissionService {
  Future<DriverMission?> getActiveMission() async {
    final response =
        await ApiService.authenticatedGet('/api/driver/missions/active');
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('Ce compte ne dispose pas du role chauffeur.');
    }
    if (response.statusCode != 200) {
      throw Exception(_extractError(
        response.body,
        'Impossible de recuperer la mission active.',
      ));
    }

    final decoded = jsonDecode(response.body);
    if (decoded == null) return null;
    if (decoded is! Map) {
      throw const FormatException('Reponse de mission invalide.');
    }
    return DriverMission.fromJson(
      decoded.map((key, value) => MapEntry('$key', value)),
    );
  }

  Future<DriverMission> updateStatus({
    required String missionId,
    required String action,
  }) async {
    final response = await ApiService.authenticatedPost(
      '/api/driver/missions/$missionId/status',
      <String, dynamic>{'action': action},
    );
    if (response.statusCode != 200) {
      throw Exception(_extractError(
        response.body,
        'Le statut de la mission n’a pas pu etre mis a jour.',
      ));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Reponse de mission invalide.');
    }
    return DriverMission.fromJson(
      decoded.map((key, value) => MapEntry('$key', value)),
    );
  }

  Future<List<LatLng>> fetchRoute({
    required AppLocation origin,
    required AppLocation destination,
  }) async {
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}',
      const <String, String>{
        'overview': 'full',
        'geometries': 'geojson',
      },
    );

    try {
      final response = await http.get(uri, headers: const <String, String>{
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return _fallbackRoute(origin, destination);
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['routes'] is! List) {
        return _fallbackRoute(origin, destination);
      }
      final routes = decoded['routes'] as List;
      if (routes.isEmpty || routes.first is! Map) {
        return _fallbackRoute(origin, destination);
      }
      final geometry = (routes.first as Map)['geometry'];
      final coordinates = geometry is Map ? geometry['coordinates'] : null;
      if (coordinates is! List) {
        return _fallbackRoute(origin, destination);
      }

      final points = coordinates
          .whereType<List>()
          .where((coordinate) =>
              coordinate.length >= 2 &&
              coordinate[0] is num &&
              coordinate[1] is num)
          .map(
            (coordinate) => LatLng(
              (coordinate[1] as num).toDouble(),
              (coordinate[0] as num).toDouble(),
            ),
          )
          .toList(growable: false);
      return points.isEmpty ? _fallbackRoute(origin, destination) : points;
    } catch (_) {
      return _fallbackRoute(origin, destination);
    }
  }

  List<LatLng> _fallbackRoute(
    AppLocation origin,
    AppLocation destination,
  ) {
    return <LatLng>[
      LatLng(origin.latitude, origin.longitude),
      LatLng(destination.latitude, destination.longitude),
    ];
  }

  String _extractError(String raw, String fallback) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Keep the user-facing fallback.
    }
    return fallback;
  }
}
