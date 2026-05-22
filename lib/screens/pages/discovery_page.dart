import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/hotel_service.dart';
import '../../services/location_service.dart';
import '../../models/hotel_model.dart';
import '../../theme/app_colors.dart';
import '../hotel_selection_screen.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final HotelService _hotelService = HotelService();
  final TextEditingController _searchController = TextEditingController();
  List<Hotel> _featuredHotels = [];
  List<Hotel> _searchResults = [];
  bool _isSearching = false;
  String? _searchCity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    final hotels = await _hotelService.getFeaturedEstablishments();
    if (mounted) {
      setState(() {
        _featuredHotels = hotels;
        _isLoading = false;
      });
    }
  }

  Future<void> _showLocationDialog() async {
    if (!mounted) return;
    final dialogContext = context;
    final cityCtrl = TextEditingController();
    final locationService = LocationService();

    await showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext alertContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Où recherchez-vous ?",
          style:
              GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(
                hintText: "Entrez une ville (ex: Abidjan)",
                prefixIcon:
                    Icon(Icons.location_city, color: AppColors.gradientBlue),
              ),
            ),
            const SizedBox(height: 20),
            Text("OU",
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(alertContext);
                  final loc = await locationService.getCurrentLocation();
                  if (loc != null) {
                    if (!mounted) return;
                    setState(() => _searchCity = loc.city ?? "Abidjan");
                    navigator.pop();
                  }
                },
                icon: const Icon(Icons.my_location, color: Colors.white),
                label: const Text("Ma position actuelle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (cityCtrl.text.isNotEmpty) {
                setState(() => _searchCity = cityCtrl.text);
                Navigator.pop(alertContext);
              }
            },
            child: const Text("Valider",
                style: TextStyle(
                    color: AppColors.gradientBlue,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    if (_searchCity == null) {
      await _showLocationDialog();
      if (_searchCity == null) return;
    }

    setState(() => _isLoading = true);
    final results =
        await _hotelService.searchEstablishments(query, city: _searchCity);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.gradientBlue))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isSearching) ...[
                          _buildSectionTitle("Nos Pépites (Sponsorisé)"),
                          const SizedBox(height: 12),
                          ..._featuredHotels
                              .map((h) => _buildEstablishmentCard(h)),
                        ] else ...[
                          _buildSectionTitle("Résultats de recherche"),
                          const SizedBox(height: 12),
                          if (_searchResults.isEmpty)
                            const Center(
                                child: Text("Aucun établissement trouvé"))
                          else
                            ..._searchResults
                                .map((h) => _buildEstablishmentCard(h)),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Rechercher un hôtel, restau, ville...',
          prefixIcon: const Icon(Icons.search, color: AppColors.gradientBlue),
          filled: true,
          fillColor: AppColors.lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildEstablishmentCard(Hotel hotel) {
    final isHotel = hotel.type == 'hotel';

    return GestureDetector(
      onTap: () {
        // Maintenant on ouvre l'écran de sélection pour TOUT (Hotel, Restau, Cinéma)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HotelSelectionScreen(
              hotel: hotel,
              city: hotel.city,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 160,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hotel.type.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${hotel.rating} (${hotel.reviewCount} avis)",
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: AppColors.grayText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hotel.address,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: AppColors.grayText),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed:
                            null, // Le GestureDetector parent gère la navigation
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gradientBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          isHotel ? "Chambres" : "Réserver",
                          style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
