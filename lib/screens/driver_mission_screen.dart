import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/driver_mission_model.dart';
import '../models/ride_model.dart';
import '../services/auth_service.dart';
import '../services/driver_mission_service.dart';
import '../theme/app_colors.dart';

class DriverMissionScreen extends StatefulWidget {
  const DriverMissionScreen({super.key});

  @override
  State<DriverMissionScreen> createState() => _DriverMissionScreenState();
}

class _DriverMissionScreenState extends State<DriverMissionScreen> {
  final DriverMissionService _missionService = DriverMissionService();
  final MapController _mapController = MapController();

  DriverMission? _mission;
  List<LatLng> _routePoints = const <LatLng>[];
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMission();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadMission(silent: true),
    );
  }

  Future<void> _loadMission({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final mission = await _missionService.getActiveMission();
      final route = mission == null
          ? const <LatLng>[]
          : await _missionService.fetchRoute(
              origin: mission.ride.pickupLocation,
              destination: mission.ride.destinationLocation,
            );
      if (!mounted) return;
      setState(() {
        _mission = mission;
        _routePoints = route;
        _isLoading = false;
        _error = null;
      });
      _fitRoute();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _updateStatus(String action) async {
    final mission = _mission;
    if (mission == null || _isUpdating) return;

    setState(() => _isUpdating = true);
    try {
      final updated = await _missionService.updateStatus(
        missionId: mission.ride.id,
        action: action,
      );
      if (!mounted) return;
      setState(() {
        _mission = updated;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mise a jour impossible : $error')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _fitRoute() {
    if (_routePoints.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_routePoints),
          padding: const EdgeInsets.all(44),
        ),
      );
    });
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mission Active',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Se deconnecter',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            )
          : RefreshIndicator(
              onRefresh: _loadMission,
              child: _mission == null
                  ? _buildEmptyMission()
                  : _buildMission(_mission!),
            ),
    );
  }

  Widget _buildEmptyMission() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.route_outlined,
          size: 72,
          color: AppColors.orange,
        ),
        const SizedBox(height: 18),
        const Text(
          'Aucune mission active',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Les nouvelles affectations de votre entreprise apparaitront ici automatiquement.',
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildMission(DriverMission mission) {
    final ride = mission.ride;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _missionHeader(mission),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  ride.pickupLocation.latitude,
                  ride.pickupLocation.longitude,
                ),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.drift.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.orange,
                      strokeWidth: 5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    _marker(
                      ride.pickupLocation.latitude,
                      ride.pickupLocation.longitude,
                      Icons.my_location,
                    ),
                    _marker(
                      ride.destinationLocation.latitude,
                      ride.destinationLocation.longitude,
                      Icons.flag,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _addressCard(
          icon: Icons.trip_origin,
          label: 'Depart client',
          value: ride.origin,
        ),
        const SizedBox(height: 8),
        _addressCard(
          icon: Icons.location_on,
          label: 'Destination',
          value: ride.destination,
        ),
        const SizedBox(height: 20),
        _actionButtons(ride),
        const SizedBox(height: 24),
        const Text(
          'TIMELINE DU PACK',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        if (ride.packTimeline.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Aucune prestation additionnelle dans ce trajet.'),
            ),
          )
        else
          ...ride.packTimeline.map(_timelineTile),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _missionHeader(DriverMission mission) {
    final vehicle = mission.vehicle;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mission.companyName,
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _statusLabel(mission.ride.status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (vehicle != null) ...[
            const SizedBox(height: 8),
            Text(
              '${vehicle.name} · ${vehicle.registrationNumber}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButtons(Ride ride) {
    final canStart = {
      RideStatus.requested,
      RideStatus.accepted,
      RideStatus.scheduled,
    }.contains(ride.status);
    final canArrive = {
      RideStatus.inProgress,
      RideStatus.overtime,
    }.contains(ride.status);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                canStart && !_isUpdating ? () => _updateStatus('start') : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Demarrer'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canArrive && !_isUpdating
                ? () => _updateStatus('arrived')
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Arrive'),
          ),
        ),
      ],
    );
  }

  Widget _timelineTile(Map<String, dynamic> item) {
    final day = (item['day'] as num?)?.toInt();
    final time = item['time']?.toString() ?? '';
    final title = item['title']?.toString() ?? 'Prestation';
    final subtitle = item['subtitle']?.toString() ?? '';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.orange.withValues(alpha: 0.12),
          foregroundColor: AppColors.orange,
          child: Text(day == null ? '-' : '$day'),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('$time${subtitle.isEmpty ? '' : ' · $subtitle'}'),
      ),
    );
  }

  Widget _addressCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.orange),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(value),
      ),
    );
  }

  Marker _marker(
    double latitude,
    double longitude,
    IconData icon,
  ) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 44,
      height: 44,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.orange,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  String _statusLabel(RideStatus status) {
    return switch (status) {
      RideStatus.requested => 'Mission a accepter',
      RideStatus.accepted => 'Mission affectee',
      RideStatus.scheduled => 'Mission planifiee',
      RideStatus.inProgress => 'Trajet en cours',
      RideStatus.overtime => 'Trajet en overtime',
      RideStatus.arrived => 'Arrivee confirmee',
      RideStatus.completed => 'Mission terminee',
      RideStatus.cancelled => 'Mission annulee',
      RideStatus.restricted => 'Mission restreinte',
      RideStatus.pending => 'Mission en attente',
    };
  }
}
