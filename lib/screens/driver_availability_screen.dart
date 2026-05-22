import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location_model.dart';
import '../models/ride_option_model.dart';
import '../models/driver_model.dart';
import '../services/driver_availability_service.dart';
import '../theme/app_colors.dart';

class DriverAvailabilityScreen extends StatefulWidget {
  final Location currentLocation;
  final Location destination;
  final RideOption selectedOption;

  const DriverAvailabilityScreen({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.selectedOption,
  });

  @override
  State<DriverAvailabilityScreen> createState() =>
      _DriverAvailabilityScreenState();
}

class _DriverAvailabilityScreenState extends State<DriverAvailabilityScreen> {
  late DriverAvailabilityService _driverService;
  List<Driver> _nearbyDrivers = [];
  bool _isLoading = true;
  Driver? _selectedDriver;

  @override
  void initState() {
    super.initState();
    _driverService = DriverAvailabilityService();
    _searchNearbyDrivers();
  }

  Future<void> _searchNearbyDrivers() async {
    try {
      final drivers = await _driverService.findNearbyDrivers(
        location: widget.currentLocation,
        radiusKm: 5.0,
      );

      if (mounted) {
        setState(() {
          _nearbyDrivers = drivers;
          if (drivers.isNotEmpty) {
            _selectedDriver = drivers.first;
          }
          _isLoading = false;
        });
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

  void _confirmRide() {
    if (_selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un chauffeur')),
      );
      return;
    }

    // Simule l'acceptation du trajet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(
          'Trajet confirmé avec ${_selectedDriver!.name}!\n'
          'Arrivée estimée: ${_selectedDriver!.eta} minutes',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _driverService.dispose();
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
          'Chauffeurs disponibles',
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
          : _nearbyDrivers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun chauffeur disponible',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veuillez réessayer dans quelques instants',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // RÉSUMÉ DE LA COMMANDE
                      _buildOrderSummary(),
                      const SizedBox(height: 24),

                      // CHAUFFEURS DISPONIBLES
                      Text(
                        'Chauffeurs à proximité (${_nearbyDrivers.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._nearbyDrivers.asMap().entries.map((entry) {
                        final driver = entry.value;
                        final isSelected = _selectedDriver?.id == driver.id;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDriver = driver),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Nom, Rating, ETA
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            driver.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.star,
                                                  size: 14,
                                                  color: Colors.amber[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${driver.rating} (${driver.reviewCount} avis)',
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
                                    // ETA BADGE
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha:0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green.withValues(alpha:0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule,
                                              size: 14,
                                              color: Colors.green[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${driver.eta} min',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // VÉHICULE
                                Row(
                                  children: [
                                    Icon(Icons.directions_car,
                                        size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${driver.vehicleColor} - ${driver.licensePlate}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // NUMÉRO TÉL
                                Row(
                                  children: [
                                    Icon(Icons.phone,
                                        size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text(
                                      driver.phoneNumber,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),

                                // Checkbox
                                if (isSelected) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E90FF)
                                          .withValues(alpha:0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Color(0xFF1E90FF)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sélectionné',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E90FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                          onPressed: _confirmRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E90FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Confirmer le trajet',
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

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de votre trajet',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedOption.label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${widget.selectedOption.price.toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              Chip(
                label: Text(
                  widget.selectedOption.estimatedTime,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.blue[300]!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
