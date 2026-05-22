import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../models/cart_model.dart';
import 'paiement_page.dart';

class HotelDetailPage extends StatefulWidget {
  final HotelModel hotel;
  const HotelDetailPage({super.key, required this.hotel});

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  final PageController _imgController = PageController();
  int _currentImg = 0;
  int _duration = 1; // Durée en jours/nuits
  String? _addedRoomId;
  String? _budgetRoomId;
  double _travelBudget = 280000;
  bool _dinnerPackReserved = true;

  // 360 modal state
  int _view360ImgIndex = 0;
  double _view360Zoom = 1.0;

  static const List<Map<String, dynamic>> _amenityIcons = [
    {'label': 'Piscine', 'icon': Icons.pool},
    {'label': 'Spa', 'icon': Icons.spa},
    {'label': 'WiFi', 'icon': Icons.wifi},
    {'label': 'Restaurant', 'icon': Icons.restaurant},
    {'label': 'Bar', 'icon': Icons.local_bar},
    {'label': 'Gym', 'icon': Icons.fitness_center},
    {'label': 'Parking', 'icon': Icons.local_parking},
    {'label': 'Conférence', 'icon': Icons.meeting_room},
    {'label': 'Plage', 'icon': Icons.beach_access},
    {'label': 'Casino', 'icon': Icons.casino},
    {'label': 'Water sports', 'icon': Icons.surfing},
    {'label': 'Ponton', 'icon': Icons.directions_boat},
    {'label': 'Visite guidée', 'icon': Icons.tour},
    {'label': 'Restaurant Gastronomique', 'icon': Icons.restaurant_menu},
    {'label': 'Bar Rooftop', 'icon': Icons.roofing},
    {'label': 'Restaurant Poissons', 'icon': Icons.set_meal},
    {'label': 'Plage privée', 'icon': Icons.beach_access},
    {'label': 'Restaurant colonial', 'icon': Icons.restaurant},
    {'label': 'Restaurant Gastronomique', 'icon': Icons.restaurant_menu},
  ];

  IconData _iconForAmenity(String label) {
    final match = _amenityIcons.firstWhere(
      (e) => e['label'] == label,
      orElse: () => {'icon': Icons.check_circle_outline},
    );
    return match['icon'] as IconData;
  }

  @override
  void dispose() {
    _imgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildImageCarousel(context, hotel)),
              SliverToBoxAdapter(child: _buildHotelInfo(hotel)),
              SliverToBoxAdapter(child: _buildGuestFirstOverview(hotel)),
              SliverToBoxAdapter(child: _buildAmenities(hotel)),
              SliverToBoxAdapter(child: _buildBudgetLivingCard(hotel)),
              SliverToBoxAdapter(child: _buildMajordomeCard()),
              SliverToBoxAdapter(child: _buildRoomsTitle()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildRoomCard(context, hotel.rooms[i]),
                  childCount: hotel.rooms.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildFixedActions(context, hotel),
          ),
        ],
      ),
    );
  }

  // ─── Carrousel d'images ────────────────────────────────────────────────────
  Widget _buildImageCarousel(BuildContext context, HotelModel hotel) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imgController,
            onPageChanged: (i) => setState(() => _currentImg = i),
            itemCount: hotel.imageSeeds.length,
            itemBuilder: (_, i) => Image.network(
              hotel.imageSeeds[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.lightGray,
                child: const Center(
                    child: Icon(Icons.hotel,
                        size: 60, color: AppColors.lightText)),
              ),
            ),
          ),
          // Gradient bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bouton retour
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          // Indicateurs de pages
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                hotel.imageSeeds.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImg == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentImg == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Infos hôtel ──────────────────────────────────────────────────────────
  Widget _buildHotelInfo(HotelModel hotel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on,
                          color: AppColors.grayText, size: 14),
                      const SizedBox(width: 3),
                      Text(hotel.location,
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: AppColors.grayText)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(
                        hotel.stars,
                        (_) => const Icon(Icons.star,
                            color: Colors.amber, size: 14)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.blueViolet,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hotel.description,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.grayText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Équipements ──────────────────────────────────────────────────────────
  RoomModel _selectedBudgetRoom(HotelModel hotel) {
    if (hotel.rooms.isEmpty) {
      return RoomModel(
        id: 'fallback',
        name: 'Suite Signature',
        priceDisplay: '0 FCFA',
        priceValue: 0,
        imageSeed: '',
        gallerySeeds: <String>[],
      );
    }
    final roomId = _budgetRoomId ?? hotel.rooms.first.id;
    return hotel.rooms.firstWhere(
      (room) => room.id == roomId,
      orElse: () => hotel.rooms.first,
    );
  }

  String _formatMoney(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  Map<String, int> _budgetBuckets(HotelModel hotel) {
    final room = _selectedBudgetRoom(hotel);
    final remaining = (_travelBudget.round() - (room.priceValue * _duration))
        .clamp(0, 9999999)
        .toInt();
    return {
      'Transport': (remaining * 0.35).round(),
      'Resto': (remaining * 0.30).round(),
      'Loisirs': (remaining * 0.20).round(),
      'Shopping': (remaining * 0.15).round(),
    };
  }

  Widget _buildGuestFirstOverview(HotelModel hotel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF122033), Color(0xFF1D3557)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guest First',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visite 360, vue balcon, simulation budget et creation de compte seulement au moment du booking.',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SpecChip(label: '360'),
                _SpecChip(label: 'Balcon'),
                _SpecChip(label: 'Reste a vivre'),
                _SpecChip(label: 'Paiement fractionne'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetLivingCard(HotelModel hotel) {
    final room = _selectedBudgetRoom(hotel);
    final stayCost = room.priceValue * _duration;
    final remaining = _travelBudget.round() - stayCost;
    final buckets = _budgetBuckets(hotel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reste a vivre',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Si je prends ${room.name} pour $_duration nuit(s), il me reste ${_formatMoney(remaining < 0 ? 0 : remaining)}.',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: AppColors.grayText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: room.id,
              decoration: InputDecoration(
                labelText: 'Chambre de reference',
                filled: true,
                fillColor: AppColors.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: hotel.rooms
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _budgetRoomId = value);
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget voyage',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  _formatMoney(_travelBudget.round()),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
            Slider(
              value: _travelBudget,
              min: 120000,
              max: 950000,
              divisions: 83,
              activeColor: AppColors.orange,
              onChanged: (value) => setState(() => _travelBudget = value),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _budgetLine('Hebergement', stayCost, AppColors.darkText),
                  const SizedBox(height: 8),
                  _budgetLine('Transport', buckets['Transport'] ?? 0,
                      AppColors.gradientBlue),
                  _budgetLine('Resto', buckets['Resto'] ?? 0, AppColors.orange),
                  _budgetLine(
                      'Loisirs', buckets['Loisirs'] ?? 0, AppColors.green),
                  _budgetLine('Shopping', buckets['Shopping'] ?? 0,
                      AppColors.gradientPurple),
                ],
              ),
            ),
            if ((buckets['Resto'] ?? 0) == 0 || remaining < 40000) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Budget resto tendu : le guide intelligent basculera vers des options street-food autour de l hotel.',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    height: 1.45,
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _budgetLine(String label, int amount, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ),
        Text(
          _formatMoney(amount),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMajordomeCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Guide intelligent',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _dinnerPackReserved,
                  activeThumbColor: AppColors.orange,
                  onChanged: (value) =>
                      setState(() => _dinnerPackReserved = value),
                ),
              ],
            ),
            Text(
              'Zero spam : seulement les informations liees aux prestations reservees.',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 11,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            _majordomeCue('J-1', 'GPS hotel debloque'),
            _majordomeCue('Arrivee', 'Code WiFi et check-in prioritaire'),
            if (_dinnerPackReserved)
              _majordomeCue('19:00', 'Suggestion resto car pack diner reserve'),
          ],
        ),
      ),
    );
  }

  Widget _majordomeCue(String moment, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                moment,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(HotelModel hotel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Équipements',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hotel.amenities.length,
              itemBuilder: (_, i) => _amenityChip(hotel.amenities[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenityChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child: Icon(_iconForAmenity(label), size: 22, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label.length > 8 ? '${label.substring(0, 7)}…' : label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Inventaire chambres ───────────────────────────────────────────────────
  Widget _buildRoomsTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text(
        'Inventaire des Chambres Disponibles',
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.darkText,
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    final isAdded = _addedRoomId == room.id;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAdded ? Border.all(color: AppColors.green, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo chambre
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              room.imageSeed,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: AppColors.lightGray,
                child: const Center(
                  child: Icon(Icons.bed, size: 40, color: AppColors.lightText),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    Text(
                      '${(room.priceValue * _duration).toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Boutons Vidéo 360° et Voir les Pièces
                Row(
                  children: [
                    Expanded(
                      child: _roomActionBtn(
                        icon: Icons.threed_rotation,
                        label: 'Vidéo 360°',
                        onTap: () => _show360Modal(context, room),
                        isGradient: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _roomActionBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'Voir les Pièces',
                        onTap: () => _showGalleryModal(context, room),
                        isGradient: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Sélecteur de durée (Jours/Nuits)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Durée du séjour',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grayText)),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppColors.gradientBlue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove,
                                size: 16, color: AppColors.darkText),
                            onPressed: () {
                              if (_duration > 1) setState(() => _duration--);
                            },
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          Text('$_duration Jours',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gradientBlue)),
                          IconButton(
                            icon: const Icon(Icons.add,
                                size: 16, color: AppColors.darkText),
                            onPressed: () => setState(() => _duration++),
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Boutons Panier / Réserver seul
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _addToCart(context, room),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 44,
                          decoration: BoxDecoration(
                            color: isAdded ? AppColors.green : null,
                            gradient: isAdded ? null : AppColors.blueViolet,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAdded
                                    ? Icons.check
                                    : Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAdded
                                    ? 'Ajouté au Panier'
                                    : 'Ajouter au Panier',
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
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _reserveNow(context, room),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Réserver',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }

  Widget _roomActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isGradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gradientBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppColors.blueViolet.createShader(b),
              child: Icon(icon, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gradientBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────
  void _addToCart(BuildContext context, RoomModel room) {
    CartModel.add(CartItem(
      id: room.id,
      type: 'hotel',
      name: widget.hotel.name,
      subtitle: '${room.name} · $_duration jour(s)',
      priceDisplay: '${room.priceValue * _duration} FCFA',
      priceValue: room.priceValue * _duration,
      color: AppColors.gradientBlue,
      icon: Icons.hotel,
    ));
    setState(() => _addedRoomId = room.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${room.name} ($_duration jours) ajouté au panier !',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reserveNow(BuildContext context, RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaiementPage(
          items: [
            CartItem(
              id: room.id,
              type: 'hotel',
              name: widget.hotel.name,
              subtitle: '${room.name} · $_duration jour(s)',
              priceDisplay: '${room.priceValue * _duration} FCFA',
              priceValue: room.priceValue * _duration,
              color: AppColors.gradientBlue,
              icon: Icons.hotel,
            )
          ],
        ),
      ),
    );
  }

  // ─── Bouton fixe bas ──────────────────────────────────────────────────────
  Widget _buildFixedActions(BuildContext context, HotelModel hotel) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Ajouter au Panier',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ─── Modales ──────────────────────────────────────────────────────────────
  void _show360Modal(BuildContext context, RoomModel room) {
    setState(() {
      _view360ImgIndex = 0;
      _view360Zoom = 1.0;
    });
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) => AppColors.blueViolet.createShader(b),
                    child: const Icon(Icons.threed_rotation,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vidéo 360° — ${room.name}',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: Colors.white54, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Gallery d'angles avec labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(3, (index) {
                  final labels = ['Panoramique', 'Balcon', 'Détail'];
                  final isActive = _view360ImgIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _view360ImgIndex = index),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index < 2 ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.gradientBlue.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.gradientBlue
                                : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w800 : FontWeight.w500,
                            color: isActive ? Colors.white : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            // Viewport interactif 360°
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF111111),
              ),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 2.5,
                onInteractionUpdate: (details) =>
                    setState(() => _view360Zoom = details.scale),
                child: Stack(
                  children: [
                    // Image de la chambre (zoom/pan simulé)
                    Center(
                      child: Transform.scale(
                        scale: _view360Zoom,
                        child: Image.network(
                          room.imageSeed,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1A1A2E),
                            child: const Center(
                              child: Icon(Icons.threed_rotation,
                                  size: 64, color: Color(0xFF1E90FF)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Badge angle
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '360° · Visite interactive',
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Indicateur zoom
                    if (_view360Zoom > 1.2)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Zoom ${(_view360Zoom * 100).toInt()}%',
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Contrôles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ctrl360(Icons.rotate_left, 'Gauche'),
                  _ctrl360(Icons.zoom_in, 'Zoom'),
                  _ctrl360(Icons.rotate_right, 'Droite'),
                  _ctrl360(Icons.volcano_outlined,
                      _view360Zoom > 1.2 ? 'Réduire' : 'Plein écran'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrl360(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  void _showGalleryModal(BuildContext context, RoomModel room) {
    showDialog(
      context: context,
      builder: (_) => _GalleryModal(room: room),
    );
  }
}

// ─── Galerie des pièces ────────────────────────────────────────────────────
class _GalleryModal extends StatefulWidget {
  final RoomModel room;
  const _GalleryModal({required this.room});

  @override
  State<_GalleryModal> createState() => _GalleryModalState();
}

class _GalleryModalState extends State<_GalleryModal> {
  int _page = 0;
  final PageController _ctrl = PageController();

  static const List<String> _labels = ['Chambre', 'Salle de Bain', 'Dressing'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seeds = widget.room.gallerySeeds;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) => AppColors.blueViolet.createShader(b),
                  child: const Icon(Icons.photo_library,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.room.name,
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close,
                      color: AppColors.grayText, size: 22),
                ),
              ],
            ),
          ),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                seeds.length.clamp(0, 3),
                (i) => GestureDetector(
                  onTap: () {
                    setState(() => _page = i);
                    _ctrl.animateToPage(i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: _page == i ? AppColors.blueViolet : null,
                      color: _page == i ? null : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      i < _labels.length ? _labels[i] : 'Pièce ${i + 1}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _page == i ? Colors.white : AppColors.grayText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Images
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: SizedBox(
              height: 240,
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: seeds.length,
                itemBuilder: (_, i) => Image.network(
                  seeds[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.lightGray,
                    child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: AppColors.lightText, size: 40)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String label;

  const _SpecChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
