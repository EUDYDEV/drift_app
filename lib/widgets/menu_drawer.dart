import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../screens/menu/settings_page.dart';
import '../screens/menu/profile_page.dart';
import '../screens/menu/premium_page.dart';
import '../screens/menu/help_page.dart';
import '../screens/menu/history_page.dart';
import '../screens/auth/login_screen.dart';
import '../screens/pages/majordome_brief_page.dart';
import '../services/auth_service.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        elevation: 16,
        child: Container(
          width: MediaQuery.of(context).size.width *
              0.75, // Prend 75% de la largeur
          height: double.infinity,
          color: AppColors.white,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildMenuItem(
                          context, Icons.person_outline, 'Mon Profil', () {
                        Navigator.pop(context); // 1. Fermer le menu
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => auth.isAuthenticated
                                    ? const ProfilePage()
                                    : const LoginScreen()));
                      }),
                      if (auth.isAuthenticated) ...[
                        _buildMenuItem(
                            context, Icons.settings_outlined, 'Paramètres', () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsPage()));
                        }),
                        _buildMenuItem(
                            context, Icons.star_border, 'Abonnement VIP', () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PremiumPage()));
                        }),
                        _buildMenuItem(context, Icons.hotel_class_outlined,
                            'Mode Majordome', () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MajordomeBriefPage()));
                        }),
                        _buildMenuItem(
                            context, Icons.history, 'Historique des trajets',
                            () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HistoryPage()));
                        }),
                      ],
                      _buildMenuItem(
                          context, Icons.help_outline, 'Aide & Assistance', () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HelpPage()));
                      }),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFEEEEEE)),
                if (auth.isAuthenticated)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: _buildMenuItem(context, Icons.logout, 'Déconnexion',
                        () {
                      auth.logout();
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false);
                    }, color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthService>();
    final displayName = auth.isAuthenticated && auth.userName.isNotEmpty
        ? auth.userName
        : 'Invité';
    final membershipLabel = !auth.isAuthenticated
        ? 'Se connecter'
        : auth.isVip
            ? 'Membre VIP'
            : 'Membre';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.blueViolet,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    membershipLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context), // Bouton croix pour fermer
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.lightGray,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, size: 18, color: AppColors.darkText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color color = AppColors.darkText}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color:
            Colors.transparent, // Important pour rendre toute la zone cliquable
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color:
                    color == AppColors.darkText ? AppColors.grayText : color),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.montserrat(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.lightText),
          ],
        ),
      ),
    );
  }
}
