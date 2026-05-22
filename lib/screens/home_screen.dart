import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import 'immediate_ride_screen.dart';
import 'reservation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LocationService _locationService;
  Location? _currentLocation;
  final TextEditingController _destinationController = TextEditingController();
  bool _isLoadingLocation = true;
  bool _showServiceOptions = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _initializeLocation();
  }

  void _onDestinationChanged() {
    final hasText = _destinationController.text.trim().isNotEmpty;
    if (hasText != _showServiceOptions) {
      setState(() => _showServiceOptions = hasText);
    }
  }

  Future<void> _initializeLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentLocation = location;
        _isLoadingLocation = false;
      });
      // Démarre l'écoute en temps réel
      _destinationController.addListener(_onDestinationChanged);
      _locationService.startLocationListener();
    }
  }

  void _goToImmediateRide() {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une destination')),
      );
      return;
    }
    // Ajout d'une vérification pour s'assurer que la localisation est disponible
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'obtenir votre position actuelle. Veuillez réessayer.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImmediateRideScreen(
          currentLocation: _currentLocation!,
          destination: _destinationController.text,
        ),
      ),
    );
  }

  void _goToReservation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReservationScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _locationService.stopLocationListener();
    _locationService.dispose();
    _destinationController.removeListener(_onDestinationChanged);
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // MAP BACKGROUND (placeholder)
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.5,
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 50, color: Colors.blue),
                  const SizedBox(height: 10),
                  if (_isLoadingLocation)
                    const Text('Localisation en cours...')
                  else if (_currentLocation != null)
                    Text(
                      _currentLocation!.address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    )
                  else
                    const Text('Impossible de localiser'),
                ],
              ),
            ),
          ),

          // MAIN CONTENT
          SingleChildScrollView(
            child: Column(
              children: [
                // Espacement pour la carte
                SizedBox(height: MediaQuery.of(context).size.height * 0.4),

                // CARD PRINCIPALE
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITRE
                      Text(
                        'Où allez-vous?',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CHAMP DE DESTINATION
                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Entrez votre destination',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E90FF),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_showServiceOptions) ...[
                        // DEUX OPTIONS
                        Text(
                          'Choisissez votre service',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // OPTION 1: COMMANDER IMMÉDIATEMENT
                        _buildOptionButton(
                          title: 'Commander immédiatement',
                          subtitle: 'Un chauffeur arrive en quelques minutes',
                          icon: Icons.directions_car,
                          color: const Color(0xFF1E90FF),
                          onTap: _goToImmediateRide,
                        ),
                        const SizedBox(height: 12),

                        // OPTION 2: RÉSERVER POUR PLUS TARD
                        _buildOptionButton(
                          title: 'Réserver pour plus tard',
                          subtitle: 'Transport + Hôtel avec paiement à la fin',
                          icon: Icons.calendar_today,
                          color: const Color(0xFF00B894),
                          onTap: _goToReservation,
                        ),
                      ],
                      const SizedBox(height: 20),

                      // INFO
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Prices affichés avec taxes incluses',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
