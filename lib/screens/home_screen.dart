import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../controllers/home_journey_controller.dart';
import '../models/location_model.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../widgets/ride_timing_dialog.dart';
import 'auth/login_screen.dart';
import 'immediate_ride_screen.dart';
import 'reservation_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppLocation? sharedLocation;
  const HomeScreen({super.key, this.sharedLocation});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LocationService _locationService;
  late HomeJourneyController _journeyController;
  AppLocation? _currentLocation;
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  final MapController _mapController = MapController();
  LatLng? _destinationCoordinates;
  List<LatLng> _routePoints = [];
  Timer? _debounce;
  bool _isSearching = false;
  RideTimingSelection? _timingSelection;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _journeyController = context.read<HomeJourneyController>();
    _locationService.addListener(() {
      if (mounted) {
        setState(() => _currentLocation = _locationService.currentLocation);
      }
    });
    _destinationController.addListener(_onTextChanged);
    _initializeLocation();
  }

  void _initializeLocation() async {
    final loc = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() => _currentLocation = loc);
      if (widget.sharedLocation != null) {
        _applySharedDestination(widget.sharedLocation!);
      }
      _locationService.startLocationListener();
      _resumePendingJourney();
    }
  }

  void _resumePendingJourney() {
    final pending = _journeyController.pendingDestination;
    if (pending == null || !context.read<AuthService>().isAuthenticated) {
      return;
    }
    _applySharedDestination(pending);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openTimingForDestination();
    });
  }

  void _applySharedDestination(AppLocation sharedLocation) {
    setState(() {
      _destinationController.text = sharedLocation.address;
      _destinationCoordinates = LatLng(
        sharedLocation.latitude,
        sharedLocation.longitude,
      );
      _suggestions = [];
    });
    if (_currentLocation != null) {
      _fetchRoute(_destinationCoordinates!);
      _fitMap(_destinationCoordinates!);
    }
  }

  void _onTextChanged() {
    final text = _destinationController.text.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (text.length >= 3) {
        _searchLocation(text);
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&lat=5.3484&lon=-4.0305&limit=5');
    try {
      final request = await HttpClient().getUrl(url);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        final List features = data['features'];
        if (mounted) {
          setState(() {
            _suggestions = features.map((f) {
              final props = f['properties'];
              final coords = f['geometry']['coordinates'];
              return {
                'display':
                    '${props['name'] ?? ''}, ${props['city'] ?? props['state'] ?? 'Abidjan'}',
                'lat': coords[1],
                'lon': coords[0],
              };
            }).toList();
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _validateDestination(String address) async {
    if (address.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locations =
          await geocoding.locationFromAddress("$address, Abidjan");
      if (locations.isNotEmpty) {
        final loc = locations.first;
        await _selectLocation(
            {'display': address, 'lat': loc.latitude, 'lon': loc.longitude});
        return;
      }
    } catch (e) {
      if (_suggestions.isNotEmpty) {
        await _selectLocation(_suggestions.first);
        return;
      }
    }
    setState(() => _isSearching = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lieu introuvable. Touchez la carte pour choisir.')));
  }

  Future<void> _selectLocation(Map<String, dynamic> suggestion) async {
    final dest = LatLng(suggestion['lat'], suggestion['lon']);
    final destination = AppLocation(
      latitude: dest.latitude,
      longitude: dest.longitude,
      address: suggestion['display'],
      city: _extractCity(suggestion['display']),
      country: "Côte d'Ivoire",
    );
    setState(() {
      _destinationController.text = suggestion['display'];
      _destinationCoordinates = dest;
      _suggestions = [];
      _isSearching = false;
    });
    _fetchRoute(dest);
    _fitMap(dest);
    FocusScope.of(context).unfocus();
    _journeyController.rememberDestination(destination);

    if (!context.read<AuthService>().isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    await _openTimingForDestination();
  }

  Future<void> _openTimingForDestination() async {
    _destinationFocusNode.unfocus();
    final selection = await showRideTimingDialog(context);
    if (selection == null || !mounted) return;

    setState(() => _timingSelection = selection);
    _journeyController.consumeDestination();
    _continueRideFlow();
  }

  String _extractCity(String address) {
    final parts = address.split(',');
    return parts.length > 1 ? parts.last.trim() : address.trim();
  }

  void _continueRideFlow() {
    final timing = _timingSelection;
    if (timing == null) return;

    if (timing.isImmediate) {
      _openImmediateRideFlow();
    } else {
      _openReservationFlow(scheduledStart: timing.scheduledStart);
    }
  }

  Future<void> _fetchRoute(LatLng destination) async {
    if (_currentLocation == null) return;
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson');
    try {
      final request = await HttpClient().getUrl(url);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final List coords = data['routes'][0]['geometry']['coordinates'];
        if (mounted) {
          setState(() => _routePoints = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList());
        }
      }
    } catch (e) {
      setState(() => _routePoints = [
            LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
            destination
          ]);
    }
  }

  void _fitMap(LatLng dest) {
    if (_currentLocation == null) return;
    final bounds = LatLngBounds.fromPoints([
      LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
      dest
    ]);
    _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  AppLocation? _resolvedDestinationLocation() {
    final coordinates = _destinationCoordinates;
    if (coordinates == null) {
      return widget.sharedLocation;
    }

    return AppLocation(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      address: _destinationController.text.trim().isEmpty
          ? 'Destination'
          : _destinationController.text.trim(),
      city: 'Abidjan',
      country: "Cote d'Ivoire",
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _openImmediateRideFlow() {
    if (!context.read<AuthService>().isAuthenticated) {
      _openLogin();
      return;
    }

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Votre position actuelle est en cours de recuperation.'),
        ),
      );
      return;
    }

    final destinationText = _destinationController.text.trim();
    if (destinationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner une destination.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImmediateRideScreen(
          currentLocation: _currentLocation!,
          destination: destinationText,
          destinationLocation: _resolvedDestinationLocation(),
        ),
      ),
    );
  }

  void _openReservationFlow({DateTime? scheduledStart}) {
    if (!context.read<AuthService>().isAuthenticated) {
      _openLogin();
      return;
    }

    final destinationText = _destinationController.text.trim();
    if (destinationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner une destination.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationScreen(
          initialCity: destinationText,
          initialDepartureDate: scheduledStart,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationService.stopLocationListener();
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.55,
            child: _currentLocation != null
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_currentLocation!.latitude,
                          _currentLocation!.longitude),
                      initialZoom: 15,
                      onTap: (tapPos, point) => _selectLocation({
                        'display': 'Point choisi',
                        'lat': point.latitude,
                        'lon': point.longitude
                      }),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'ci.drift.travel.app.v1', // FIX 403
                      ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(polylines: [
                          Polyline(
                              points: _routePoints,
                              strokeWidth: 5,
                              color: const Color(0xFF1E90FF))
                        ]),
                      MarkerLayer(markers: [
                        Marker(
                            point: LatLng(_currentLocation!.latitude,
                                _currentLocation!.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location,
                                color: Colors.blue, size: 30)),
                        if (_destinationCoordinates != null)
                          Marker(
                              point: _destinationCoordinates!,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40)),
                      ]),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 20)
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Où allez-vous?',
                          style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _destinationController,
                        focusNode: _destinationFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _validateDestination,
                        decoration: InputDecoration(
                          hintText: 'Palmeraie, Maison B...',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF1E90FF)),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)))
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      if (_suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[200]!)),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) => ListTile(
                              leading: const Icon(Icons.location_on,
                                  color: Colors.grey, size: 20),
                              title: Text(_suggestions[index]['display'],
                                  style: const TextStyle(fontSize: 14)),
                              onTap: () => _selectLocation(_suggestions[index]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
