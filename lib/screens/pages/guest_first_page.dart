import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/hotel_model.dart';
import '../../theme/app_colors.dart';
import '../../models/room_model.dart';
import '../hotel_detail_page.dart';

class GuestFirstPage extends StatefulWidget {
  final HotelModel hotel;

  const GuestFirstPage({super.key, required this.hotel});

  @override
  State<GuestFirstPage> createState() => _GuestFirstPageState();
}

class _GuestFirstPageState extends State<GuestFirstPage> {
  static const List<_VibeChoice> _vibes = [
    _VibeChoice(
      label: 'Business',
      icon: Icons.work_outline,
      subtitle: 'facture pro, chauffeur fiable, wifi calme',
      accent: Color(0xFF1E90FF),
    ),
    _VibeChoice(
      label: 'Romantique',
      icon: Icons.favorite_border,
      subtitle: 'balcon, diner reserve, ambiance douce',
      accent: Color(0xFFE57373),
    ),
    _VibeChoice(
      label: 'Famille',
      icon: Icons.family_restroom,
      subtitle: 'espaces larges, loisirs, budget tenu',
      accent: Color(0xFF43A047),
    ),
    _VibeChoice(
      label: 'Fetard',
      icon: Icons.nightlife_outlined,
      subtitle: 'night out, retour securise, restos tardifs',
      accent: Color(0xFFFFA000),
    ),
  ];

  int _selectedVibe = 0;
  int _selectedRoom = 0;
  int _selectedImmersion = 0;
  int _nights = 2;
  double _tripBudget = 240000;
  double _noise = 28;

  HotelModel get _hotel => widget.hotel;

  RoomModel get _room => _hotel.rooms[_selectedRoom.clamp(
      0, (_hotel.rooms.isEmpty ? 1 : _hotel.rooms.length) - 1)];

  int get _stayCost => _room.priceValue * _nights;

  int get _remainingBudget =>
      (_tripBudget.round() - _stayCost).clamp(-9999999, 9999999);

  Map<String, int> get _budgetBuckets {
    final remaining = _remainingBudget < 0 ? 0 : _remainingBudget;
    final vibe = _vibes[_selectedVibe].label;
    if (vibe == 'Business') {
      return _spread(remaining, const [40, 25, 15, 20]);
    }
    if (vibe == 'Romantique') {
      return _spread(remaining, const [20, 35, 25, 20]);
    }
    if (vibe == 'Famille') {
      return _spread(remaining, const [25, 25, 35, 15]);
    }
    return _spread(remaining, const [35, 30, 20, 15]);
  }

  static Map<String, int> _spread(int amount, List<int> weights) {
    final labels = ['Transport', 'Resto', 'Loisirs', 'Shopping'];
    final values = <String, int>{};
    var allocated = 0;
    for (var i = 0; i < labels.length; i++) {
      final value = (amount * weights[i] / 100).round();
      values[labels[i]] = value;
      allocated += value;
    }
    if (labels.isNotEmpty) {
      values[labels.last] = (values[labels.last] ?? 0) + (amount - allocated);
    }
    return values;
  }

  String get _noiseLabel {
    if (_noise < 25) return 'Tres calme';
    if (_noise < 45) return 'Calme premium';
    if (_noise < 65) return 'Anime mais gere';
    return 'Night life assume';
  }

  String _formatFcfa(int value) {
    final raw = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    final prefix = value < 0 ? '- ' : '';
    return '$prefix${buffer.toString()} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 290,
            backgroundColor: const Color(0xFF10151E),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _hotel.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration:
                          const BoxDecoration(gradient: AppColors.blueViolet),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha:0.15),
                          Colors.black.withValues(alpha:0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 26,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            'Guest First · visite avant compte',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _hotel.name,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_hotel.location} · ${_hotel.rating.toStringAsFixed(1)} / 5',
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Etape 0 · Quelle vibe cherchez-vous ?'),
                  const SizedBox(height: 14),
                  _buildVibes(),
                  const SizedBox(height: 26),
                  _sectionTitle('Etape 1 · Visitez avant de reserver'),
                  const SizedBox(height: 14),
                  _buildImmersionCard(),
                  const SizedBox(height: 26),
                  _sectionTitle('Etape 2 · Simulez votre reste a vivre'),
                  const SizedBox(height: 14),
                  _buildBudgetCard(),
                  const SizedBox(height: 26),
                  _sectionTitle('Etape 3 · Paiement flexible et sans friction'),
                  const SizedBox(height: 14),
                  _buildCheckoutPreview(),
                  const SizedBox(height: 26),
                  _sectionTitle('Guide intelligent'),
                  const SizedBox(height: 14),
                  _buildMajordomePreview(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HotelDetailPage(hotel: _hotel),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppColors.gradientBlue, width: 1.5),
                  foregroundColor: AppColors.gradientBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Continuer sans compte',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HotelDetailPage(hotel: _hotel),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Je reserve',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildVibes() {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_vibes.length, (index) {
            final vibe = _vibes[index];
            final selected = _selectedVibe == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedVibe = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 158,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      selected ? vibe.accent.withValues(alpha:0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? vibe.accent : const Color(0xFFE7E1D7),
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: vibe.accent.withValues(alpha:0.16),
                      child: Icon(vibe.icon, color: vibe.accent, size: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      vibe.label,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vibe.subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        height: 1.45,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E1D7)),
          ),
          child: Row(
            children: [
              Icon(_vibes[_selectedVibe].icon,
                  color: _vibes[_selectedVibe].accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Parcours adapte ${_vibes[_selectedVibe].label.toLowerCase()} : recommandations, budget et notifications ne montrent que ce que vous avez reserve.',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    height: 1.45,
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImmersionCard() {
    final tabs = ['Chambre 360', 'Balcon', 'Bruit nocturne'];
    final gallery =
        _room.gallerySeeds.isEmpty ? [_room.imageSeed] : _room.gallerySeeds;
    final imageIndex = _selectedImmersion.clamp(0, gallery.length - 1);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(tabs.length, (index) {
              final selected = _selectedImmersion == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImmersion = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(
                        right: index == tabs.length - 1 ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.darkText
                          : const Color(0xFFF4F0E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        tabs[index],
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : AppColors.grayText,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.28,
                  child: Image.network(
                    gallery[imageIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE5EDF8),
                      child: const Center(
                        child: Icon(Icons.threed_rotation,
                            size: 48, color: AppColors.gradientBlue),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedImmersion == 2
                          ? _noiseLabel
                          : tabs[_selectedImmersion],
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.92),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            size: 16, color: AppColors.gradientBlue),
                        const SizedBox(width: 6),
                        Text(
                          'Zero friction avant compte',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedRoom,
                  decoration: InputDecoration(
                    labelText: 'Chambre',
                    filled: true,
                    fillColor: const Color(0xFFF7F2EA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: List.generate(_hotel.rooms.length, (index) {
                    final room = _hotel.rooms[index];
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(room.name),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedRoom = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vue balcon',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedImmersion == 1
                            ? 'lagune, piscine, coucher de soleil'
                            : 'disponible dans la visite immersive',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedImmersion == 2)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Simulateur de bruit nocturne',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    Text(
                      '${_noise.round()} dB',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _noise,
                  min: 10,
                  max: 75,
                  activeColor: AppColors.orange,
                  onChanged: (value) => setState(() => _noise = value),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    final budget = _budgetBuckets;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1726), Color(0xFF172033)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Si je prends ${_room.name}, il me reste',
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatFcfa(_remainingBudget),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _sliderBlock(
                  label: 'Budget global',
                  value: _tripBudget,
                  min: 120000,
                  max: 950000,
                  onChanged: (value) => setState(() => _tripBudget = value),
                  trailing: _formatFcfa(_tripBudget.round()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sliderBlock(
                  label: 'Nuits',
                  value: _nights.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  onChanged: (value) => setState(() => _nights = value.round()),
                  trailing: '$_nights nuit${_nights > 1 ? 's' : ''}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _budgetRow('Hebergement', _stayCost, Colors.white),
                const SizedBox(height: 10),
                _budgetRow('Transport', budget['Transport'] ?? 0,
                    const Color(0xFF70D6FF)),
                _budgetRow(
                    'Resto', budget['Resto'] ?? 0, const Color(0xFFFFC857)),
                _budgetRow(
                    'Loisirs', budget['Loisirs'] ?? 0, const Color(0xFF57CC99)),
                _budgetRow('Shopping', budget['Shopping'] ?? 0,
                    const Color(0xFFF28482)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if ((budget['Resto'] ?? 0) == 0 ||
              _remainingBudget < _stayCost * 0.15)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF243049),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_dining_outlined,
                      color: AppColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Budget resto serre : DriFt vous poussera plutot des adresses street-food autour de ${_hotel.city}.',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sliderBlock({
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
    required String trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trailing,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.orange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _budgetRow(String label, int value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          _formatFcfa(value),
          style: GoogleFonts.montserrat(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutPreview() {
    final splitOptions = [
      'Carte bancaire',
      'Mobile Money',
      'Paiement fractionne',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E1D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: splitOptions
                .map(
                  (label) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F2EA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creation de compte express',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nom, telephone, email. Le compte DriFt se cree a la fin du paiement sans casser votre visite.',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    height: 1.45,
                    color: AppColors.grayText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajordomePreview() {
    const items = [
      _MajordomeCue('J-1', 'GPS de l hotel',
          'Votre itineraire hotel sera revele seulement a l approche.'),
      _MajordomeCue('Arrivee', 'Code WiFi',
          'Le code wifi et le check-in arrivent au bon moment, pas avant.'),
      _MajordomeCue('19:00', 'Suggestion diner',
          'Si le pack diner est reserve, l app pousse la bonne table.'),
    ];

    return Column(
      children: items.map((item) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: AppColors.blueViolet,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.moment,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.grayText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _VibeChoice {
  final String label;
  final IconData icon;
  final String subtitle;
  final Color accent;

  const _VibeChoice({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.accent,
  });
}

class _MajordomeCue {
  final String moment;
  final String title;
  final String subtitle;

  const _MajordomeCue(this.moment, this.title, this.subtitle);
}
