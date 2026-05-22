import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/hotels_data.dart';
import '../../data/vip_packs_data.dart';
import '../../models/cart_model.dart';
import '../../models/hotel_model.dart';
import '../../theme/app_colors.dart';
import '../city_hotels_page.dart';
import '../custom_trip_page.dart';
import '../hotel_detail_page.dart';
import 'all_vip_packs_page.dart';
import 'chauffeur_detail_page.dart';
import 'concierge_page.dart';
import 'guest_first_page.dart';
import 'vip_pack_detail_page.dart';

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  static const _vibes = ['Tout', 'Business', 'Romantique', 'Famille', 'Fetard'];
  int _selectedVibe = 0;

  List<HotelModel> get _filteredHotels {
    if (_selectedVibe == 0) return kHotels;
    final vibe = _vibes[_selectedVibe];
    final results = kHotels.where((hotel) => _matchesVibe(hotel, vibe)).toList();
    return results.isEmpty ? kHotels : results;
  }

  bool _matchesVibe(HotelModel hotel, String vibe) {
    final amenityBlob = hotel.amenities.join(' ').toLowerCase();
    final city = hotel.city.toLowerCase();
    if (vibe == 'Business') {
      return city == 'abidjan' ||
          amenityBlob.contains('conference') ||
          amenityBlob.contains('wifi');
    }
    if (vibe == 'Romantique') {
      return city.contains('assinie') ||
          amenityBlob.contains('plage') ||
          amenityBlob.contains('spa');
    }
    if (vibe == 'Famille') {
      return amenityBlob.contains('piscine') ||
          amenityBlob.contains('water') ||
          hotel.rooms.length > 2;
    }
    return city == 'abidjan' || amenityBlob.contains('bar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildVibeFilters()),
              SliverToBoxAdapter(child: _buildGuestFirstBanner(context)),
              SliverToBoxAdapter(child: _buildNightOutBanner(context)),
              SliverToBoxAdapter(child: _buildCustomTripBanner(context)),
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  'DriFt Experiences VIP',
                  onViewAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllVipPacksPage()),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildExperiencesList(context)),
              SliverToBoxAdapter(
                child: _buildSectionTitle('Destinations Populaires'),
              ),
              SliverToBoxAdapter(child: _buildDestinationsCarousel(context)),
              SliverToBoxAdapter(
                child: _buildSectionTitle('Decouvrir les offres'),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildHotelCard(context, _filteredHotels[i]),
                  childCount: _filteredHotels.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildDiscoverButton(context),
          ),
          Positioned(
            bottom: 90,
            right: 20,
            child: _buildConciergeFab(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Ou voulez-vous aller ?',
            hintStyle: GoogleFonts.montserrat(
              color: AppColors.grayText,
              fontSize: 14,
            ),
            prefixIcon: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppColors.blueViolet.createShader(b),
              child: const Icon(Icons.search, color: Colors.white),
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.blueViolet,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildVibeFilters() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => _vibeChip(i),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _vibes.length,
      ),
    );
  }

  Widget _vibeChip(int index) {
    final active = _selectedVibe == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedVibe = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.darkText : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.darkText : const Color(0xFFE4E7EE),
          ),
        ),
        child: Center(
          child: Text(
            _vibes[index],
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : AppColors.grayText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestFirstBanner(BuildContext context) {
    final hotel = _filteredHotels.first;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GuestFirstPage(hotel: hotel)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF132238), Color(0xFF203C69)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Guest First',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Visitez la chambre en 360, testez le bruit nocturne et calculez votre reste a vivre avant meme de creer un compte.',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureCapsule(label: 'Vue balcon'),
                _FeatureCapsule(label: 'Budget maitrise'),
                _FeatureCapsule(label: 'Paiement fractionne'),
                _FeatureCapsule(label: 'Zero spam'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => AppColors.blueViolet.createShader(b),
                child: Text(
                  'Voir tout ->',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationsCarousel(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: kDestinations.length,
        itemBuilder: (_, i) => _buildDestinationItem(context, kDestinations[i]),
      ),
    );
  }

  Widget _buildDestinationItem(BuildContext context, Map<String, String> dest) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CityHotelsPage(city: dest['name']!)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      dest['url']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration:
                            const BoxDecoration(gradient: AppColors.blueViolet),
                        child: Center(
                          child: Text(dest['emoji']!, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha:0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dest['name']!,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelCard(BuildContext context, HotelModel hotel) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: hotel)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Stack(
                children: [
                  Image.network(
                    hotel.coverImage,
                    height: 172,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 172,
                      decoration: const BoxDecoration(gradient: AppColors.blueViolet),
                      child: const Center(
                        child: Icon(Icons.hotel, size: 60, color: Colors.white38),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            hotel.rating.toString(),
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hotel.category,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
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
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          hotel.stars,
                          (_) => const Icon(Icons.star, color: Colors.amber, size: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.grayText, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        hotel.location,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InlineSpecChip(label: '360'),
                      _InlineSpecChip(label: 'Balcon'),
                      _InlineSpecChip(label: 'Reste a vivre'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A partir de',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: AppColors.grayText,
                            ),
                          ),
                          Text(
                            hotel.priceDisplay,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppColors.blueViolet,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gradientBlue.withValues(alpha:0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Decouvrir',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

  Widget _buildDiscoverButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuestFirstPage(hotel: _filteredHotels.first),
        ),
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.blueViolet,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientBlue.withValues(alpha:0.45),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Tester Guest First',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNightOutBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChauffeurDetailPage(
            option: kChauffeurOptions[1],
            initialDuration: 0,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_taxi, color: Color(0xFFFFD700), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode Night Out',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chauffeur securise, vetting visible et suivi GPS en 1 clic.',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTripBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomTripPage()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.blueViolet,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientBlue.withValues(alpha:0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creer sur mesure',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Definissez votre budget, vos jours et votre niveau de confort',
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withValues(alpha:0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildExperiencesList(BuildContext context) {
    final pack = kVipPacks[0];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VipPackDetailPage(pack: pack)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'PACK WEEK-END',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Evasion Assinie Premium',
              style: GoogleFonts.montserrat(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chauffeur AR + 1 Nuit Palm Royal + diner',
              style: GoogleFonts.montserrat(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '250 000 FCFA',
                  style: GoogleFonts.montserrat(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    CartModel.add(
                      CartItem(
                        id: 'pack_assinie_${DateTime.now().millisecondsSinceEpoch}',
                        type: 'pack',
                        name: 'Pack Evasion Assinie',
                        subtitle: 'Tout inclus',
                        priceDisplay: '250 000 FCFA',
                        priceValue: 250000,
                        color: const Color(0xFF111827),
                        icon: Icons.workspace_premium,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pack ajoute au panier')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Ajouter',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConciergeFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConciergePage()),
      ),
      backgroundColor: AppColors.orange,
      child: const Icon(Icons.support_agent, color: Colors.white),
    );
  }
}

class _FeatureCapsule extends StatelessWidget {
  final String label;

  const _FeatureCapsule({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineSpecChip extends StatelessWidget {
  final String label;

  const _InlineSpecChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gradientBlue.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.gradientBlue,
        ),
      ),
    );
  }
}
