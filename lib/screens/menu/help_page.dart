import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        title: Text(
          'AIDE & ASSISTANCE',
          style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Bloc Assistance 24/7
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.blueViolet,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Assistance 24/7',
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notre équipe est disponible pour vous accompagner à tout moment.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.gradientBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                  child: Text('LANCER LE CHAT',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          Text(
            'Questions Fréquentes (FAQ)',
            style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText),
          ),
          const SizedBox(height: 16),

          _buildFaqItem('Comment annuler une réservation ?',
              'Vous pouvez annuler depuis l\'onglet "Panier" ou "Historique" jusqu\'à 24h avant l\'heure prévue sans frais.'),
          _buildFaqItem('Les chauffeurs sont-ils fiables ?',
              'Absolument. Tous nos chauffeurs partenaires sont soumis à une vérification rigoureuse de leurs antécédents.'),
          _buildFaqItem('Comment fonctionne le paiement ?',
              'Le paiement est sécurisé et s\'effectue directement via l\'application (Mobile Money ou Carte Bancaire) après confirmation.'),
          _buildFaqItem('Puis-je modifier ma destination en cours de route ?',
              'Oui, vous pouvez demander à votre chauffeur de modifier l\'itinéraire, le tarif sera ajusté automatiquement.'),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.gradientBlue,
          title: Text(question,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: AppColors.grayText, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
