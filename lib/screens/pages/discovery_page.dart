import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/experience_filter_controller.dart';
import '../../models/cart_model.dart';
import '../../models/hotel_model.dart';
import '../../models/location_model.dart';
import '../../models/partner_catalog_prestation.dart';
import '../../services/hotel_service.dart';
import '../../services/location_service.dart';
import '../../services/partner_catalog_service.dart';
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

  late final ExperienceFilterController _experienceFilterController;
  late final PartnerCatalogService _partnerCatalogService;
  late final LocationService _locationService;

  List<Hotel> _featuredHotels = <Hotel>[];
  List<Hotel> _searchResults = <Hotel>[];
  List<PartnerCatalogPrestation> _deliveryResults =
      <PartnerCatalogPrestation>[];
  bool _isSearching = false;
  bool _isLoading = true;
  Hotel? _selectedExperience;
  String _activeCity = 'Abidjan';
  String _selectedFilter = 'Tout';
  AppLocation? _currentLocation;

  bool get _showsDeliveryResults =>
      _selectedFilter != 'Tout' && _selectedFilter != 'Hotels';

  @override
  void initState() {
    super.initState();
    _experienceFilterController = context.read<ExperienceFilterController>();
    _partnerCatalogService = context.read<PartnerCatalogService>();
    _locationService = context.read<LocationService>();
    _experienceFilterController.addListener(_handleExternalFilterChanged);
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    final hotels = await _hotelService.getFeaturedEstablishments();
    if (!mounted) return;

    setState(() {
      _activeCity = 'Abidjan';
      _featuredHotels = hotels;
      _searchResults = hotels;
      _isLoading = false;
      _selectedFilter = 'Tout';
    });
  }

  Future<void> _loadHotelsForCity(String city) async {
    setState(() {
      _isLoading = true;
      _selectedExperience = null;
      _activeCity = city;
      _selectedFilter = 'Hotels';
    });

    final hotels = await _hotelService.getHotelsInCity(city);
    if (!mounted) return;

    setState(() {
      _featuredHotels = hotels;
      _searchResults = hotels;
      _isSearching = true;
      _isLoading = false;
    });
  }

  Future<void> _loadDeliveryOptions(String cuisineCategory) async {
    setState(() {
      _isLoading = true;
      _selectedExperience = null;
      _selectedFilter = cuisineCategory;
    });

    _currentLocation ??= await _locationService.getCurrentLocation();
    final prestations = await _partnerCatalogService.fetchDeliveryCatalog(
      cuisineCategory: cuisineCategory,
      nearLocation: _currentLocation,
    );

    if (!mounted) return;
    setState(() {
      _deliveryResults = prestations;
      _isSearching = true;
      _isLoading = false;
    });
  }

  Future<void> _onExternalFilterChanged() async {
    final state = _experienceFilterController.consumePendingState();
    if (state == null || state.serviceType != 'hotel') {
      return;
    }

    final city = state.city.trim();
    if (city.isEmpty) {
      return;
    }

    _searchController.text = city;
    await _loadHotelsForCity(city);
  }

  void _handleExternalFilterChanged() {
    _onExternalFilterChanged();
  }

  Future<void> _onSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = _featuredHotels;
      });
      return;
    }

    setState(() => _isLoading = true);

    final normalized = trimmed.toLowerCase();
    final cuisineCategory = switch (normalized) {
      final value when value.contains('africain') => 'Africain',
      final value when value.contains('chinois') => 'Chinois',
      final value when value.contains('europeen') ||
          value.contains('européen') =>
        'Europeen',
      _ => null,
    };

    if (cuisineCategory != null) {
      await _loadDeliveryOptions(cuisineCategory);
      return;
    }

    if (_showsDeliveryResults) {
      _currentLocation ??= await _locationService.getCurrentLocation();
      final baseResults = await _partnerCatalogService.fetchDeliveryCatalog(
        cuisineCategory: _selectedFilter,
        nearLocation: _currentLocation,
      );

      if (!mounted) return;
      setState(() {
        _deliveryResults = baseResults
            .where(
              (item) =>
                  item.name.toLowerCase().contains(trimmed.toLowerCase()) ||
                  item.partnerName.toLowerCase().contains(trimmed.toLowerCase()),
            )
            .toList(growable: false);
        _isSearching = true;
        _isLoading = false;
      });
      return;
    }

    final results =
        await _hotelService.searchEstablishments(trimmed, city: _activeCity);
    if (!mounted) return;

    setState(() {
      _searchResults = results;
      _isSearching = true;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _experienceFilterController.removeListener(_handleExternalFilterChanged);
    _searchController.dispose();
    _hotelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedExperience != null) {
      return HotelSelectionScreen(
        hotel: _selectedExperience!,
        city: _selectedExperience!.city,
        onBack: () => setState(() => _selectedExperience = null),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          _showsDeliveryResults
                              ? 'Drift Gastronomie'
                              : _isSearching
                                  ? 'Resultats'
                                  : 'Experiences Premium',
                        ),
                        const SizedBox(height: 14),
                        if (_showsDeliveryResults)
                          ..._deliveryResults.map(_buildDeliveryCard)
                        else
                          ...(_isSearching ? _searchResults : _featuredHotels)
                              .map(_buildExperienceCard),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      decoration: const BoxDecoration(color: Colors.white),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Hotel, restaurant, activite...',
          prefixIcon: const Icon(Icons.search, color: AppColors.orange),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
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
        fontWeight: FontWeight.w900,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildExperienceCard(Hotel hotel) {
    return GestureDetector(
      onTap: () => setState(() => _selectedExperience = hotel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: NetworkImage(
                    hotel.coverImage.isNotEmpty
                        ? hotel.coverImage
                        : 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800',
                  ),
                  fit: BoxFit.cover,
                ),
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
                      Text(
                        '${hotel.rating.toStringAsFixed(1)} *',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hotel.city,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(PartnerCatalogPrestation prestation) {
    final cover = prestation.mediaUrls.isNotEmpty
        ? prestation.mediaUrls.first
        : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800';
    final cuisine = prestation.cuisineCategory ?? 'Cuisine premium';
    final city = prestation.cityHint ?? _activeCity;
    final distanceLabel = _distanceLabel(prestation.partnerLocation);

    return GestureDetector(
      onTap: () => _showDeliveryDialog(prestation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: NetworkImage(cover),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prestation.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        CartModel.formatCurrency(prestation.price.round()),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${prestation.partnerName} · $cuisine',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.grayText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distanceLabel ?? city,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AppColors.grayText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeliveryDialog(PartnerCatalogPrestation prestation) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(prestation.name),
        content: Text(
          '${prestation.partnerName}\n'
          '${CartModel.formatCurrency(prestation.price.round())}\n\n'
          'Cuisine: ${prestation.cuisineCategory ?? 'Premium'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              CartModel.add(
                CartItem(
                  id: 'delivery:${prestation.id}',
                  type: 'restaurant',
                  serviceType: prestation.typeService,
                  name: prestation.name,
                  subtitle: prestation.partnerName,
                  priceDisplay: CartModel.formatCurrency(
                    prestation.price.round(),
                  ),
                  priceValue: prestation.price.round(),
                  color: AppColors.orange,
                  icon: Icons.restaurant,
                  partnerId: prestation.partnerId,
                  prestationId: prestation.id,
                  partnerName: prestation.partnerName,
                  partnerType: prestation.partnerType,
                  partnerCity: prestation.cityHint,
                  partnerAddress: prestation.partnerLocation.address,
                  partnerLatitude: prestation.partnerLocation.latitude,
                  partnerLongitude: prestation.partnerLocation.longitude,
                  metadata: <String, dynamic>{
                    'cuisineCategory': prestation.cuisineCategory,
                    'mediaUrls': prestation.mediaUrls,
                  },
                ),
              );
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prestation ajoutee au pack'),
                ),
              );
            },
            child: const Text('Ajouter au pack'),
          ),
        ],
      ),
    );
  }

  String? _distanceLabel(AppLocation partnerLocation) {
    if (_currentLocation == null) {
      return null;
    }

    final distance = _currentLocation!.distanceTo(partnerLocation);
    return '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km de vous';
  }
}
