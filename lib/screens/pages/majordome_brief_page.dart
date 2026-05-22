import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class MajordomeBriefPage extends StatelessWidget {
  const MajordomeBriefPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
            Text(
              'Votre Majordome',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        actions: [
          // Bouton SOS Intégré (Cahier des charges 5.2)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: const Icon(Icons.sos, color: Colors.red, size: 28),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // 1. GESTION BUDGÉTAIRE "RESTE À VIVRE" (Cahier des charges 5.3)
          _resteAVivreCard(),
          const SizedBox(height: 20),

          // 2. TIMELINE ACTIVE (Anticipation réelle)
          _sectionTitle('Actions en cours'),
          const SizedBox(height: 12),
          _activeContextTask(
            title: 'GPS Hôtel disponible',
            desc: 'Trajet vers "Le Wafou 4*" optimisé.',
            time: 'Actif',
            icon: Icons.map_outlined,
            color: const Color(0xFF1E90FF),
            isActionable: true,
          ),
          _activeContextTask(
            title: 'WiFi & Codes d\'accès',
            desc: 'S\'activera automatiquement à 100m de l\'hôtel.',
            time: 'En attente',
            icon: Icons.lock_open_outlined,
            color: Colors.grey,
            isActionable: false,
          ),

          const SizedBox(height: 20),

          // 3. MODULE MOBILITÉ (Cahier des charges 5.2)
          _sectionTitle('Votre Chauffeur'),
          const SizedBox(height: 12),
          _driverStatusCard(
            name: 'Kader',
            status: 'En route',
            car: 'Toyota Prado • CI-225-AB',
            rating: '4.9',
          ),
        ],
      ),
    );
  }

  Widget _resteAVivreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientBlue, AppColors.gradientPurple],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESTE À VIVRE',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '124,500 FCFA',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          // Barre de progression budget par catégorie
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Budget resto épuisé : Suggestions Street-food activées.',
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeContextTask({
    required String title,
    required String desc,
    required String time,
    required IconData icon,
    required Color color,
    required bool isActionable,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                Text(desc,
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          if (isActionable)
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.orange)
          else
            Text(time,
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _driverStatusCard(
      {required String name,
      required String status,
      required String car,
      required String rating}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=kader'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(rating,
                        style: GoogleFonts.montserrat(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(car,
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(status,
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.gradientBlue,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientBlue,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.call, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}
