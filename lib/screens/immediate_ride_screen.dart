import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location_model.dart';
import '../models/ride_option_model.dart';
import '../services/location_service.dart';
import '../services/ride_service.dart';
import '../theme/app_colors.dart';
import 'driver_availability_screen.dart';

class ImmediateRideScreen extends StatefulWidget {
  final Location currentLocation;
  final String destination;

  const ImmediateRideScreen({
    super.key,
    required this.currentLocation,
    required this.destination,
  });

  @override
  State<ImmediateRideScreen> createState() => _ImmediateRideScreenState();
}

class _ImmediateRideScreenState extends State<ImmediateRideScreen> {
  late RideService _rideService;
  late LocationService _locationService;
  List<RideOption> _rideOptions = [];
  bool _isLoading = true;
  Location? _destinationLocation;
  RideOption? _selectedOption;

  @override
  void initState() {
    super.initState();
    _rideService = RideService();
    _locationService = LocationService();
    _loadRideOptions();
  }

  Future<void> _loadRideOptions() async {
    try {
      // Obtient les coordonnées de destination
      _destinationLocation =
          await _locationService.getCoordinatesFromAddress(widget.destination);

      if (_destinationLocation != null) {
        // Récupère les options de trajet
        final options = await _rideService.getRideOptions(
          from: widget.currentLocation,
          to: _destinationLocation!,
        );

        if (mounted) {
          setState(() {
            _rideOptions = options;
            if (options.isNotEmpty) {
              _selectedOption = options.first;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _proceedToDriverSearch() {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une option')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverAvailabilityScreen(
          currentLocation: widget.currentLocation,
          destination: _destinationLocation!,
          selectedOption: _selectedOption!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rideService.dispose();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Commander immédiatement',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E90FF),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TRAJET INFO
                  _buildTripInfo(),
                  const SizedBox(height: 24),

                  // OPTIONS DE TRAJET
                  Text(
                    'Choisissez votre option',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._rideOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedOption?.type == option.type;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedOption = option),
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: index < _rideOptions.length - 1 ? 12 : 0,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1E90FF)
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? const Color(0xFF1E90FF).withValues(alpha:0.05)
                              : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        option.type == RideType.withDriver
                                            ? Icons.person // Changed from person_filled
                                            : Icons.directions_car,
                                        color: const Color(0xFF1E90FF),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        option.label,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    option.description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule,
                                          size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        option.estimatedTime,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${option.price.toStringAsFixed(0)} FCFA',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E90FF),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tarif estimé',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E90FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            else
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceedToDriverSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E90FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Rechercher un chauffeur',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTripInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Départ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      widget.currentLocation.address,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destination',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      widget.destination,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
