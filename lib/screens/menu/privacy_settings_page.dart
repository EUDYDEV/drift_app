import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_preferences_controller.dart';
import '../../models/cart_model.dart';
import '../../theme/app_theme.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferencesController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          preferences.languageCode == 'fr' ? 'CONFIDENTIALITÉ' : 'PRIVACY',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _privacyCard(
            context,
            icon: Icons.location_searching,
            title: preferences.languageCode == 'fr'
                ? 'Partage de la position en arrière-plan'
                : 'Background location sharing',
            value: preferences.backgroundLocationSharing,
            onChanged: preferences.setBackgroundLocationSharing,
          ),
          _privacyCard(
            context,
            icon: Icons.history_toggle_off,
            title: preferences.languageCode == 'fr'
                ? 'Historique des trajets visible par les partenaires'
                : 'Trip history visible to partners',
            value: preferences.partnerTripHistoryVisible,
            onChanged: preferences.setPartnerTripHistoryVisible,
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDeletion(context, preferences),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(
                preferences.languageCode == 'fr'
                    ? 'Supprimer définitivement mes données de navigation'
                    : 'Permanently delete my navigation data',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            preferences.languageCode == 'fr'
                ? 'Cette action supprime les positions enregistrées, les tickets locaux, les sessions Wi-Fi et le panier actuel.'
                : 'This removes saved locations, local tickets, Wi-Fi sessions and the current cart.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.orange,
        secondary: Icon(icon, color: AppTheme.orange),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletion(
    BuildContext context,
    AppPreferencesController preferences,
  ) async {
    final isFrench = preferences.languageCode == 'fr';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isFrench ? 'Supprimer les données ?' : 'Delete navigation data?',
        ),
        content: Text(
          isFrench
              ? 'Cette suppression est définitive sur cet appareil.'
              : 'This deletion is permanent on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isFrench ? 'Annuler' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isFrench ? 'Supprimer' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await preferences.deleteNavigationData();
    CartModel.clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFrench
              ? 'Données de navigation supprimées.'
              : 'Navigation data deleted.',
        ),
      ),
    );
  }
}
