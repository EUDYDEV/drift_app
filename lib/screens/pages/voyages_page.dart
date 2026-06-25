import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class VoyagesPage extends StatefulWidget {
  const VoyagesPage({super.key});

  @override
  State<VoyagesPage> createState() => _VoyagesPageState();
}

class _VoyagesPageState extends State<VoyagesPage> {
  int _selectedTab = 0;

  // Demain, cette liste sera alimentée par ton API/Base de données.
  // Exemple de structure : { 'id', 'title', 'type', 'date', 'price', 'status', 'image' }
  final List<Map<String, dynamic>> _activities = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(child: _buildCategoryFilters()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              sliver: _activities.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildPremiumEmptyState(),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildActivityCard(_activities[index]),
                      childCount: _activities.length,
                    ),
                  ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: _buildExploreButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 30, 25, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes Activités',
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.darkText,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gérez vos réservations premium',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        children: [
          _tabItem(0, 'En cours', Icons.auto_awesome_rounded),
          const SizedBox(width: 12),
          _tabItem(1, 'À venir', Icons.calendar_today_rounded),
          const SizedBox(width: 12),
          _tabItem(2, 'Historique', Icons.history_rounded),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkText : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.darkText.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
          border: isSelected ? null : Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.grayText),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.event_available_outlined, size: 50, color: Colors.grey.withValues(alpha: 0.2)),
        ),
        const SizedBox(height: 30),
        Text(
          'Aucune activité',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Text(
            'Vos futures expériences de voyage et réservations s\'afficheront ici en temps réel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.grayText,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Structure prête pour tes données réelles
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.network(activity['image'], height: 160, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(activity['title'], style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(activity['status'], style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(activity['location'], style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'EXPLORER LES EXPÉRIENCES',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
