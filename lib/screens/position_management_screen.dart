import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

class PositionManagementScreen extends StatefulWidget {
  final AppLocation currentLocation;
  final Function(AppLocation)? onLocationUpdated;

  const PositionManagementScreen({
    super.key,
    required this.currentLocation,
    this.onLocationUpdated,
  });

  @override
  State<PositionManagementScreen> createState() =>
      _PositionManagementScreenState();
}

class _PositionManagementScreenState extends State<PositionManagementScreen> {
  late LocationService _locationService;
  AppLocation? _selectedLocation;
  bool _isLoading = false;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _selectedLocation = widget.currentLocation;
    _addressController.text = widget.currentLocation.address;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _setCurrentPosition() async {
    setState(() => _isLoading = true);
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _selectedLocation = location;
          _addressController.text = location.address;
          _isLoading = false;
        });
        // Appeler le callback pour mettre à jour la position dans le header
        if (widget.onLocationUpdated != null) {
          widget.onLocationUpdated!(location);
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible d\'obtenir la position actuelle')),
        );
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

  Future<void> _sharePosition() async {
    if (_selectedLocation == null) return;

    // Créer un lien deep link avec les coordonnées
    final lat = _selectedLocation!.latitude;
    final lon = _selectedLocation!.longitude;
    final address = _selectedLocation!.address;

    // Format: driftapp://location?lat=...&lon=...&address=...
    final deepLink =
        'driftapp://location?lat=$lat&lon=$lon&address=${Uri.encodeComponent(address)}';

    final shareText =
        'Ma position: $address\n\nCoordonnées: $lat, $lon\n\nLien: $deepLink';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Partage de position',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage: $e')),
        );
      }
    }
  }

  Future<void> _deletePosition() async {
    // Pour l'instant, on retourne simplement à l'écran d'accueil
    // Plus tard, on pourra sauvegarder les positions avec SharedPreferences
    Navigator.pop(context, null);
  }

  void _saveModifiedPosition() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    }
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
          'Gestion de position',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte avec la position
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _selectedLocation != null
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          _selectedLocation!.latitude,
                          _selectedLocation!.longitude,
                        ),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.drift_app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _selectedLocation!.latitude,
                                _selectedLocation!.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
            const SizedBox(height: 24),

            // Adresse
            Text(
              'Adresse',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Entrez une adresse',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Text(
              'Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Position actuelle
            _buildActionCard(
              icon: Icons.my_location,
              title: 'Position actuelle',
              description: 'Utiliser ma position GPS actuelle',
              color: const Color(0xFF1E90FF),
              onTap: _setCurrentPosition,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),

            // Partager position
            _buildActionCard(
              icon: Icons.share,
              title: 'Partager ma position',
              description: 'Envoyer ma position à quelqu\'un',
              color: const Color(0xFF00B894),
              onTap: _sharePosition,
            ),
            const SizedBox(height: 12),

            // Supprimer position
            _buildActionCard(
              icon: Icons.delete,
              title: 'Supprimer ma position',
              description: 'Retirer cette position',
              color: Colors.red,
              onTap: _deletePosition,
            ),
            const SizedBox(height: 32),

            // Bouton sauvegarder
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveModifiedPosition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E90FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sauvegarder',
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
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
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
