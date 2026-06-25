import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_preferences_controller.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../pages/majordome_brief_page.dart';
import 'history_page.dart';
import 'payment_methods_page.dart';
import 'premium_page.dart';
import 'privacy_settings_page.dart';
import 'profile_page.dart';
import 'support_chat_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final preferences = context.watch<AppPreferencesController>();
    final french = preferences.languageCode == 'fr';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          french ? 'PARAMÈTRES' : 'SETTINGS',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 18, bottom: 120),
        children: [
          _sectionTitle(
            context,
            french ? 'Paramètres du compte' : 'Account settings',
          ),
          _settingsTile(
            context,
            icon: Icons.person_outline,
            title: french ? 'Informations personnelles' : 'Personal details',
            onTap: () => _openProtected(
              context,
              auth,
              const ProfilePage(),
            ),
          ),
          _settingsTile(
            context,
            icon: Icons.payment_outlined,
            title: french ? 'Moyens de paiement' : 'Payment methods',
            onTap: () => _openProtected(
              context,
              auth,
              const PaymentMethodsPage(),
            ),
          ),
          _settingsTile(
            context,
            icon: Icons.history,
            title: french ? 'Historique des réservations' : 'Booking history',
            onTap: () => _openProtected(
              context,
              auth,
              const HistoryPage(),
            ),
          ),
          _settingsTile(
            context,
            icon: Icons.room_service_outlined,
            title: french ? 'Mode Majordome' : 'Butler mode',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MajordomeBriefPage()),
            ),
          ),
          _settingsTile(
            context,
            icon: Icons.star_border,
            iconColor: AppTheme.orange,
            title: french ? 'Abonnement Premium' : 'Premium membership',
            onTap: () => _openProtected(
              context,
              auth,
              const PremiumPage(),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(
            context,
            french ? 'Préférences' : 'Preferences',
          ),
          _settingsTile(
            context,
            icon: Icons.notifications_none,
            title: french ? 'Notifications' : 'Notifications',
            subtitle: _notificationSummary(preferences, french),
            onTap: () => _showNotifications(context, preferences),
          ),
          _settingsTile(
            context,
            icon: Icons.language,
            title: french ? 'Langue' : 'Language',
            subtitle: preferences.languageCode == 'fr' ? 'Français' : 'English',
            onTap: () => _showLanguages(context, preferences),
          ),
          _settingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: french ? 'Thème sombre' : 'Dark mode',
            trailing: Switch(
              value: preferences.darkMode,
              onChanged: preferences.setDarkMode,
              activeThumbColor: AppTheme.orange,
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, french ? 'Support' : 'Support'),
          _settingsTile(
            context,
            icon: Icons.chat_bubble_outline,
            title: french ? 'Aide & Assistance' : 'Help & Support',
            subtitle:
                french ? 'Support Drift en ligne' : 'Drift support online',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportChatPage()),
            ),
          ),
          _settingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: french ? 'Confidentialité' : 'Privacy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySettingsPage()),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 54,
              child: auth.isAuthenticated
                  ? OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthService>().logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (_) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(
                        french ? 'DÉCONNEXION' : 'SIGN OUT',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        french ? 'SE CONNECTER' : 'SIGN IN',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              preferences.darkMode
                  ? (french ? 'Mode sombre actif' : 'Dark mode active')
                  : (french ? 'Mode clair actif' : 'Light mode active'),
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProtected(
    BuildContext context,
    AuthService auth,
    Widget page,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isAuthenticated ? page : const LoginScreen(),
      ),
    );
  }

  String _notificationSummary(
    AppPreferencesController preferences,
    bool french,
  ) {
    final active = <bool>[
      preferences.pushNotifications,
      preferences.tripAlerts,
      preferences.promotionalOffers,
    ].where((value) => value).length;
    return french ? '$active sur 3 activées' : '$active of 3 enabled';
  }

  Future<void> _showNotifications(
    BuildContext context,
    AppPreferencesController preferences,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer<AppPreferencesController>(
          builder: (context, state, _) {
            final french = state.languageCode == 'fr';
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      french
                          ? 'Préférences de notifications'
                          : 'Notification preferences',
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: state.pushNotifications,
                      onChanged: state.setPushNotifications,
                      activeThumbColor: AppTheme.orange,
                      title: Text(
                        french ? 'Notifications Push' : 'Push notifications',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: state.tripAlerts,
                      onChanged: state.setTripAlerts,
                      activeThumbColor: AppTheme.orange,
                      title: Text(
                        french ? 'Alertes de trajet' : 'Trip alerts',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: state.promotionalOffers,
                      onChanged: state.setPromotionalOffers,
                      activeThumbColor: AppTheme.orange,
                      title: Text(
                        french
                            ? 'Offres promotionnelles'
                            : 'Promotional offers',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLanguages(
    BuildContext context,
    AppPreferencesController preferences,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: preferences.languageCode,
                onChanged: (value) async {
                  if (value == null) return;
                  await preferences.setLanguage(value);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      value: 'fr',
                      title: Text('Français'),
                    ),
                    RadioListTile<String>(
                      value: 'en',
                      title: Text('English'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? theme.colorScheme.onSurface)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
