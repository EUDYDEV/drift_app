import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/cart_model.dart';
import 'chat_page.dart';
import 'chauffeur_detail_page.dart';

class ChauffeurPage extends StatefulWidget {
  const ChauffeurPage({super.key});

  @override
  State<ChauffeurPage> createState() => _ChauffeurPageState();
}

class _ChauffeurPageState extends State<ChauffeurPage> {
  int _selectedDuration = 0;
  int _selectedVehicle = 1;
  int _ratingFilter = 0; // 0 = tous
  double _maxEtaMin = 15;

  static const List<String> _ratingLabels = ['Tous', '4.5+', '4.8+'];

  List<Map<String, dynamic>> get _filteredDrivers {
    final drivers = <Map<String, dynamic>>[
      {
        'name': 'Kofi Mensah',
        'plate': 'CI-1234-AB',
        'rating': 4.8,
        'eta': 3,
        'type': 'Standard',
        'color': const Color(0xFF1E90FF)
      },
      {
        'name': 'Ama Boateng',
        'plate': 'CI-5678-CD',
        'rating': 4.9,
        'eta': 5,
        'type': 'Confort',
        'color': const Color(0xFF6C63FF)
      },
      {
        'name': 'Yusuf Ibrahim',
        'plate': 'CI-9012-EF',
        'rating': 4.7,
        'eta': 4,
        'type': 'Standard',
        'color': const Color(0xFF43A047)
      },
      {
        'name': 'Estelle Koné',
        'plate': 'CI-2233-GH',
        'rating': 4.9,
        'eta': 7,
        'type': 'Luxe',
        'color': const Color(0xFFFFD700)
      },
      {
        'name': 'Ibrahim Coulibaly',
        'plate': 'CI-4455-IJ',
        'rating': 4.6,
        'eta': 9,
        'type': 'Sans Auto',
        'color': const Color(0xFF607D8B)
      },
    ];

    if (_ratingFilter == 1) {
      return drivers.where((d) => d['rating'] >= 4.5).toList();
    }
    if (_ratingFilter == 2) {
      return drivers.where((d) => d['rating'] >= 4.8).toList();
    }
    return drivers.where((d) => d['eta'] <= _maxEtaMin).toList();
  }

  static const List<String> _durations = ['12H', '24H', 'Sur mesure'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 1. Fond Carte GPS simulée
          _buildMapSection(context),
          // 2. Panneau glissant contenant le formulaire
          _buildBottomSheetContent(context),
          // 3. Bouton Flottant
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildReserveButton(),
          ),
        ],
      ),
    );
  }

  // ─── Section Carte GPS Interactive ─────────────────────────────────────────
  Widget _buildMapSection(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.55,
      child: Container(
        color: const Color(0xFFF0F3F5),
        child: CustomPaint(
          painter: _MapPainter(),
          child: Stack(
            children: [
              // Badge radar
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredDrivers.length} chauffeur${_filteredDrivers.length > 1 ? 's' : ''} à proximité',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Badge SOS — haut droite
              Positioned(
                top: 68,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.volcano, color: Colors.red, size: 28),
                            SizedBox(width: 10),
                            Text('Urgence ?',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        content: Text(
                          'En cas d\'urgence, la ligne SOS DriFt vous met en contact avec les secours et notre équipe 24h/24.',
                          style: GoogleFonts.montserrat(
                              fontSize: 13, color: AppColors.grayText),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Annuler',
                                style: GoogleFonts.montserrat(
                                    color: AppColors.grayText)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Appel SOS en cours…'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Appeler SOS'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Color(0x8CFF0000),
                            blurRadius: 12,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.volcano,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
              // Marqueurs GPS des Chauffeurs filtrés
              ..._filteredDrivers.asMap().entries.map((entry) {
                final idx = entry.key;
                final driver = entry.value;
                return _buildDriverPin(
                  driver['eta'] as double,
                  MediaQuery.of(context).size.width * 0.15 +
                      idx * (MediaQuery.of(context).size.width * 0.18),
                  driver['color'] as Color,
                );
              }),
              // Marqueur Utilisateur
              Positioned(
                top: 200,
                left: MediaQuery.of(context).size.width / 2 - 24,
                child: _buildUserPin(),
              ),
              // Boutons de contact
              Positioned(
                top: 72,
                right: 80,
                child: Column(
                  children: [
                    _buildMapActionButton(Icons.chat_bubble_outline, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatPage()),
                      );
                    }),
                    const SizedBox(height: 12),
                    _buildMapActionButton(Icons.phone_outlined, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Appel en cours...')));
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.darkText, size: 20),
      ),
    );
  }

  Widget _buildDriverPin(double top, double left, Color color) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.directions_car, size: 20, color: color),
      ),
    );
  }

  Widget _buildUserPin() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.gradientBlue.withValues(alpha:0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.gradientBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientBlue.withValues(alpha:0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Contenu du Bottom Sheet (Formulaire) ──────────────────────────────────
  Widget _buildBottomSheetContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.42,
        bottom: 120, // Espace pour le bouton flottant
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle (Poignée)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            _buildHeaderContent(),
            _buildFormFields(),
            _buildDurationSelector(),
            _buildFilterSection(context),
            _buildDriverList(context),
            _buildVehicleSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMANDER UN CHAUFFEUR',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mise à disposition ou course immédiate',
            style: GoogleFonts.montserrat(
              color: AppColors.grayText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            _compactField(Icons.my_location, 'Point de départ',
                'Position actuelle, Abidjan'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Color(0xFFE0E0E0), height: 1, indent: 36),
            ),
            _compactField(Icons.calendar_today, 'Date et Heure',
                'Aujourd\'hui, Dès maintenant'),
          ],
        ),
      ),
    );
  }

  Widget _compactField(IconData icon, String label, String value) {
    return Row(
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => AppColors.blueViolet.createShader(b),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: AppColors.grayText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durée de la mission',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_durations.length, (i) {
              final isSelected = _selectedDuration == i;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDuration = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.blueViolet : null,
                      color: isSelected ? null : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.gradientBlue.withValues(alpha:0.32),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      _durations[i],
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.grayText,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrer les chauffeurs',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grayText,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _ratingFilter = 0;
                  _maxEtaMin = 15;
                }),
                child: Text(
                  'Réinitialiser',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gradientBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_ratingLabels.length, (i) {
              final isActive = _ratingFilter == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _ratingFilter = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.gradientBlue
                          : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _ratingLabels[i],
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : AppColors.grayText,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: AppColors.grayText),
              const SizedBox(width: 8),
              Text(
                'ETA max: ${_maxEtaMin.toInt()} min',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredDrivers.length} trouvé(s)',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.gradientBlue,
              inactiveTrackColor: AppColors.gradientBlue.withValues(alpha:0.2),
              thumbColor: AppColors.gradientBlue,
              trackHeight: 4,
            ),
            child: Slider(
              value: _maxEtaMin,
              min: 3,
              max: 20,
              divisions: 17,
              onChanged: (v) => setState(() => _maxEtaMin = v),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Liste des chauffeurs filtrés ───────────────────────────────────────────
  Widget _buildDriverList(BuildContext context) {
    final drivers = _filteredDrivers;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chauffeurs disponibles',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 10),
          ...drivers.map((d) => _driverListItem(d, context)),
        ],
      ),
    );
  }

  Widget _driverListItem(Map<String, dynamic> driver, BuildContext context) {
    final eta = driver['eta'] as double;
    final rating = driver['rating'] as double;
    final plate = driver['plate'] as String;
    final name = driver['name'] as String;
    final type = driver['type'] as String;
    final color = driver['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.25), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.drive_eta, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      plate,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.grayText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      type,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.green.withValues(alpha:0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.navigation, color: AppColors.green, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${eta.toInt()} min',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type de véhicule',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: List.generate(kChauffeurOptions.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 115,
                    child: _buildVehicleCard(i),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(int index) {
    final opt = kChauffeurOptions[index];
    final isSelected = _selectedVehicle == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedVehicle = index);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChauffeurDetailPage(
              option: opt,
              initialDuration: _selectedDuration == 2 ? 0 : _selectedDuration,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? opt.accentColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? opt.accentColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isSelected)
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => LinearGradient(
                  colors: [opt.accentColor, opt.accentColor],
                ).createShader(b),
                child: Icon(opt.icon, size: 38, color: Colors.white),
              )
            else
              Icon(opt.icon, size: 38, color: AppColors.lightText),
            const SizedBox(height: 8),
            Text(
              opt.name,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isSelected ? opt.accentColor : AppColors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              opt.price12h,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '/ 12H',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                color: AppColors.grayText,
              ),
            ),
            const SizedBox(height: 8),
            ...opt.chips.take(3).map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: opt.accentColor, size: 9),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            f,
                            style: GoogleFonts.montserrat(
                              fontSize: 8.5,
                              color: AppColors.grayText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Voir détails',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    color: opt.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 7, color: opt.accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReserveButton() {
    final opt = kChauffeurOptions[_selectedVehicle];
    final dur = _durations[_selectedDuration];
    final isCustom = _selectedDuration == 2;
    final price = _selectedDuration == 1 ? opt.price24h : opt.price12h;
    final priceVal =
        _selectedDuration == 1 ? opt.priceValue24h : opt.priceValue12h;

    return GestureDetector(
      onTap: () {
        CartModel.add(CartItem(
          id: 'chauffeur_${DateTime.now().millisecondsSinceEpoch}',
          type: 'chauffeur',
          name: 'Chauffeur ${opt.name}',
          subtitle: 'Mise à disposition $dur',
          priceDisplay: isCustom ? 'Sur devis' : price,
          priceValue: isCustom ? 0 : priceVal,
          color: opt.accentColor,
          icon: opt.icon,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chauffeur ${opt.name} ($dur) ajouté au panier !',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
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
            'COMMANDER · ${opt.name} · $dur',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dessin vectoriel de la carte GPS simulée ──────────────────────────────
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Espaces Verts (Parcs)
    final parkPaint = Paint()
      ..color = const Color(0xFFDCEBDB)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromLTRBR(size.width * 0.05, size.height * 0.1, size.width * 0.35,
            size.height * 0.35, const Radius.circular(30)),
        parkPaint);
    canvas.drawRRect(
        RRect.fromLTRBR(size.width * 0.6, size.height * 0.5, size.width * 1.2,
            size.height * 0.9, const Radius.circular(50)),
        parkPaint);

    // Étendue d'eau (Lagune/Mer)
    final waterPaint = Paint()
      ..color = const Color(0xFFB1D4E0)
      ..style = PaintingStyle.fill;
    var waterPath = Path();
    waterPath.moveTo(size.width * 0.75, 0);
    waterPath.quadraticBezierTo(
        size.width * 0.85, size.height * 0.25, size.width, size.height * 0.35);
    waterPath.lineTo(size.width, 0);
    canvas.drawPath(waterPath, waterPaint);

    // Routes standard
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Route Principale / Autoroute
    final highwayPaint = Paint()
      ..color = const Color(0xFFFFE0B2)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Tracé des routes
    var path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
        size.width * 0.45, size.height * 0.45, size.width * 0.85, size.height);
    canvas.drawPath(path, highwayPaint);

    path = Path();
    path.moveTo(size.width * 0.25, 0);
    path.quadraticBezierTo(
        size.width * 0.35, size.height * 0.35, 0, size.height * 0.75);
    canvas.drawPath(path, roadPaint);

    path = Path();
    path.moveTo(size.width * 0.35, size.height * 0.35);
    path.lineTo(size.width, size.height * 0.15);
    canvas.drawPath(path, roadPaint);

    path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.75);
    path.lineTo(size.width, size.height * 0.6);
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
