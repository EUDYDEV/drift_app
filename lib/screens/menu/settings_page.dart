import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../menu/profile_page.dart';
import 'premium_page.dart';
import 'help_page.dart';
import 'payment_methods_page.dart';
import 'history_page.dart';
import 'partner_dashboard_page.dart';
import '../pages/majordome_brief_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifs = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PARAMÈTRES',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildSectionTitle('Paramètres du compte'),
            _buildSettingsTile(
                context, Icons.person_outline, 'Informations personnelles',
                onTap: () {
              if (auth.isAuthenticated) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()));
              } else {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            }),
            _buildSettingsTile(
                context, Icons.payment_outlined, 'Moyens de paiement',
                onTap: () {
              if (auth.isAuthenticated) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentMethodsPage()));
              } else {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            }),
            _buildSettingsTile(
                context, Icons.history, 'Historique des réservations',
                onTap: () {
              if (auth.isAuthenticated) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoryPage()));
              } else {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            }),
            _buildSettingsTile(
                context, Icons.room_service_outlined, 'Mode Majordome',
                onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MajordomeBriefPage()));
            }),
            _buildSettingsTile(context, Icons.space_dashboard_outlined,
                'Dashboard partenaires', onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PartnerDashboardPage()));
            }),
            _buildSettingsTile(context, Icons.star_border, 'Abonnement Premium',
                iconColor: AppColors.orange, onTap: () {
              if (auth.isAuthenticated) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PremiumPage()));
              } else {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            }),
            const SizedBox(height: 20),
            _buildSectionTitle('Préférences'),
            _buildSettingsTile(
                context, Icons.notifications_none, 'Notifications',
                trailing: Switch(
                    value: _notifs,
                    onChanged: (v) => setState(() => _notifs = v),
                    activeThumbColor: AppColors.orange)),
            _buildSettingsTile(context, Icons.language, 'Langue',
                subtitle: 'Français'),
            _buildSettingsTile(
                context, Icons.dark_mode_outlined, 'Thème sombre',
                trailing: Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    activeThumbColor: AppColors.orange)),
            const SizedBox(height: 20),
            _buildSectionTitle('Support'),
            _buildSettingsTile(
                context, Icons.help_outline, 'Aide, FAQ & Assistance',
                onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const HelpPage()));
            }),
            _buildSettingsTile(
                context, Icons.privacy_tip_outlined, 'Confidentialité',
                onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Politique de confidentialité...')));
            }),
            const SizedBox(height: 40),
            if (auth.isAuthenticated)
              _buildLogoutButton(context)
            else
              _buildLoginButton(context),
            const SizedBox(
                height:
                    120), // Espace suffisant pour ne pas être caché par la barre de navigation
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.grayText,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title,
      {String? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
      Color? iconColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor?.withValues(alpha: 0.1) ?? AppColors.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.darkText, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style:
                      GoogleFonts.montserrat(fontSize: 12, color: AppColors.grayText),
                )
              : null,
          trailing: trailing ??
              const Icon(Icons.chevron_right, color: AppColors.lightText),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.blueViolet,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientBlue.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'SE CONNECTER',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<AuthService>().logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 56,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Center(
          child: Text(
            'DÉCONNEXION',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.red,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
