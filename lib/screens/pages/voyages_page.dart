import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class VoyagesPage extends StatefulWidget {
  const VoyagesPage({super.key});

  @override
  State<VoyagesPage> createState() => _VoyagesPageState();
}

class _VoyagesPageState extends State<VoyagesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildFilters(),
                  // N'affiche la timeline que si l'onglet "En cours" (0) est sélectionné
                  if (_selectedTab == 0)
                    _buildCurrentActivities()
                  else if (_selectedTab == 1)
                    _buildUpcomingActivities()
                  else
                    _buildHistory(),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildNewTripButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MES ACTIVITÉS',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Historique et suivi en temps réel',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.grayText,
            ),
          ),
          const SizedBox(height: 20),
          // Système d'onglets
          Row(
            children: [
              _buildTab(0, 'En cours'),
              const SizedBox(width: 10),
              _buildTab(1, 'À venir'),
              const SizedBox(width: 10),
              _buildTab(2, 'Historique'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Tout', true),
            _filterChip('Transport', false),
            _filterChip('Hôtels', false),
            _filterChip('Lieux', false),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: active
              ? AppColors.gradientBlue.withValues(alpha:0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.gradientBlue : Colors.grey[300]!)),
      child: Text(label,
          style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppColors.gradientBlue : AppColors.grayText)),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkText : AppColors.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.grayText,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentActivities() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _activeDriverCard(),
          const SizedBox(height: 20),
          _buildStatusUpdate(
            title: 'Hôtel Universal',
            subtitle: 'Enregistrement prévu à 14:00',
            status: 'Confirmé',
            color: AppColors.green,
            icon: Icons.hotel,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingActivities() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildStatusUpdate(
            title: 'Le Méridien Abidjan',
            subtitle: 'Du 22 Mai au 25 Mai',
            status: 'À venir',
            color: AppColors.orange,
            icon: Icons.calendar_month,
          ),
          const SizedBox(height: 12),
          _buildStatusUpdate(
            title: 'La Pergola',
            subtitle: 'Table pour 2 — Samedi 20:00',
            status: 'Réservé',
            color: AppColors.gradientBlue,
            icon: Icons.restaurant,
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildHistoryCard(
            title: 'Course Plateau → Cocody',
            date: 'Hier, 18:45',
            price: '3 500 FCFA',
            icon: Icons.directions_car,
          ),
          _buildHistoryCard(
            title: 'Novotel Abidjan',
            date: '12 Mai - 14 Mai',
            price: '120 000 FCFA',
            icon: Icons.hotel,
          ),
          _buildHistoryCard(
            title: 'Cinéma Majestic',
            date: '08 Mai, 21:00',
            price: '10 000 FCFA',
            icon: Icons.movie,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdate(
      {required String title,
      required String subtitle,
      required String status,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.05), blurRadius: 10)
          ]),
      child: Row(
        children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText)),
              Text(subtitle,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: AppColors.grayText)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(status,
                style: GoogleFonts.montserrat(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
      {required String title,
      required String date,
      required String price,
      required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.lightGray, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grayText, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText)),
              Text(date,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: AppColors.grayText)),
            ]),
          ),
          Text(price,
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText)),
        ],
      ),
    );
  }

  Widget _activeDriverCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.gradientBlue.withValues(alpha:0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientBlue.withValues(alpha:0.14),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label "En cours"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.blueViolet,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'CHAUFFEUR PRIVÉ — EN COURS',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Infos chauffeur
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.blueViolet,
                    ),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Konan Sylvain',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Vérifié',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Chauffeur Privé · VIP',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        Text(
                          ' 4.9 · ',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText),
                        ),
                        Text(
                          'En route',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bloc Itinéraire intégré
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gradientBlue.withValues(alpha:0.2),
                          border: Border.all(
                              color: AppColors.gradientBlue, width: 3)),
                    ),
                    Container(
                      width: 2,
                      height: 24,
                      color: AppColors.lightText.withValues(alpha:0.5),
                    ),
                    const Icon(Icons.location_on,
                        color: AppColors.orange, size: 16),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Position Actuelle (Plateau)',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText)),
                      const SizedBox(height: 16),
                      Text('Mise à disposition (6h)',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('14:15',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grayText)),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('20:00',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.green)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Boutons d'action
          Row(
            children: [
              Expanded(child: _actionBtn(Icons.phone, 'Appeler')),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn(Icons.navigation, "S'y Rendre")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: AppColors.blueViolet,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientBlue.withValues(alpha:0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTripButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha:0.45),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'RÉSERVER UN NOUVEAU TRAJET',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
