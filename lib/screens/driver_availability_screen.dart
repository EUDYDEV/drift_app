import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/ride_state_controller.dart';
import '../models/driver_model.dart';
import '../models/location_model.dart';
import '../models/ride_option_model.dart';
import '../models/ride_request_details.dart';
import '../services/driver_availability_service.dart';
import '../theme/app_colors.dart';
import '../widgets/driving_license_verification_sheet.dart';
import '../widgets/ride_request_qualification_dialog.dart';

class DriverAvailabilityScreen extends StatefulWidget {
  final AppLocation currentLocation;
  final AppLocation destination;
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
  bool _isSubmitting = false;
  Driver? _selectedDriver;

  @override
  void initState() {
    super.initState();
    _driverService = DriverAvailabilityService();
    if (widget.selectedOption.type == RideType.withoutDriver) {
      _isLoading = false;
    } else {
      _searchNearbyDrivers();
    }
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

  Future<void> _confirmRide() async {
    final isSelfDrive = widget.selectedOption.type == RideType.withoutDriver;
    if (!isSelfDrive && _selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez selectionner un chauffeur')),
      );
      return;
    }

    final request = await showRideQualificationDialog(
      context: context,
      currentLocation: widget.currentLocation,
      destination: widget.destination,
      selectedOption: widget.selectedOption,
    );

    if (!mounted || request == null) return;

    if (isSelfDrive) {
      final verified = await ensureSelfDriveVerification(context);
      if (!verified || !mounted) return;
    }

    final resolvedDriver =
        isSelfDrive ? null : _resolveDriverForRequest(request);
    if (!isSelfDrive && resolvedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            request.requiresMiniCar
                ? 'Aucun mini-car disponible pour ce groupe.'
                : 'Aucun chauffeur compatible avec ${request.passengerCount} passager(s).',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final rideController = context.read<RideStateController>();
      final ride = isSelfDrive
          ? await rideController.createSelfDriveSession(request: request)
          : await rideController.createRideSession(
              driver: resolvedDriver!,
              request: request,
            );

      if (!mounted) return;
      if (resolvedDriver != null) {
        setState(() => _selectedDriver = resolvedDriver);
      }

      final shouldCancel = await showRideCreatedDialog(
        context: context,
        ride: ride,
      );

      if (shouldCancel && mounted) {
        final cancelled = await rideController.cancelActiveRide();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cancelled
                  ? 'La course a ete annulee.'
                  : 'Impossible d\'annuler la course.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Driver? _resolveDriverForRequest(RideRequestDetails request) {
    final compatibleDrivers = _nearbyDrivers
        .where((driver) => _supportsRequest(driver, request))
        .toList(growable: false);

    if (compatibleDrivers.isEmpty) {
      return null;
    }

    final selectedDriver = _selectedDriver;
    if (selectedDriver != null &&
        compatibleDrivers.any((driver) => driver.id == selectedDriver.id)) {
      return selectedDriver;
    }

    return compatibleDrivers.first;
  }

  bool _isMiniCar(Driver driver) {
    return driver.vehicleType.trim().toLowerCase() == 'mini-car';
  }

  bool _supportsRequest(Driver driver, RideRequestDetails request) {
    final hasEnoughCapacity = driver.capacity >= request.passengerCount;
    if (!hasEnoughCapacity) {
      return false;
    }

    if (request.requiresMiniCar) {
      return _isMiniCar(driver);
    }

    return true;
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
          widget.selectedOption.type == RideType.withoutDriver
              ? 'Location sans chauffeur'
              : 'Chauffeurs disponibles',
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
          : widget.selectedOption.type == RideType.withoutDriver
              ? _buildSelfDriveBody()
              : _nearbyDrivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 64,
                            color: Colors.grey[300],
                          ),
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
                            'Veuillez reessayer dans quelques instants',
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
                          _buildOrderSummary(),
                          const SizedBox(height: 24),
                          Text(
                            'Chauffeurs a proximite (${_nearbyDrivers.length})',
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
                              onTap: () =>
                                  setState(() => _selectedDriver = driver),
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
                                      ? const Color(0xFF1E90FF)
                                          .withValues(alpha: 0.05)
                                      : Colors.white,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                                  Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Colors.amber[600],
                                                  ),
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.green
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 14,
                                                color: Colors.green[600],
                                              ),
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
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.directions_car,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
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
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
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
                                    if (isSelected) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E90FF)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF1E90FF),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Selectionne',
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _confirmRide,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E90FF),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Text(
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

  Widget _buildSelfDriveBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.28),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.orange),
                SizedBox(height: 10),
                Text(
                  'Verification obligatoire',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Votre permis et vos documents d’identite doivent etre verifies avant la remise du vehicule.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _confirmRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : const Text(
                      'Verifier mes documents et continuer',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
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
            'Resume de votre trajet',
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
