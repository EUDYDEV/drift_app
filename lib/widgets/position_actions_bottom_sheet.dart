import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/location_model.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

Future<AppLocation?> showPositionActionsBottomSheet({
  required BuildContext context,
  required AppLocation currentLocation,
  required LocationService locationService,
}) {
  return showModalBottomSheet<AppLocation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PositionActionsSheet(
      currentLocation: currentLocation,
      locationService: locationService,
    ),
  );
}

class _PositionActionsSheet extends StatefulWidget {
  const _PositionActionsSheet({
    required this.currentLocation,
    required this.locationService,
  });

  final AppLocation currentLocation;
  final LocationService locationService;

  @override
  State<_PositionActionsSheet> createState() => _PositionActionsSheetState();
}

class _PositionActionsSheetState extends State<_PositionActionsSheet> {
  late final AppLocation _location = widget.currentLocation;
  bool _isBusy = false;

  Future<void> _save() async {
    setState(() => _isBusy = true);
    await widget.locationService.saveLocationForLater(_location);
    if (!mounted) return;
    setState(() => _isBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Position enregistrée')),
    );
  }

  Future<void> _search() async {
    final controller = TextEditingController(text: _location.address);
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier votre position'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Rechercher une adresse',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (query == null || query.trim().isEmpty || !mounted) return;
    setState(() => _isBusy = true);
    final result =
        await widget.locationService.getCoordinatesFromAddress(query.trim());
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse introuvable')),
      );
      return;
    }

    Navigator.pop(context, result);
  }

  Future<void> _share() async {
    await widget.locationService.shareLocation(_location);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DCE3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'VOTRE POSITION',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.darkText,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _location.address,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            if (_isBusy)
              const LinearProgressIndicator(minHeight: 2)
            else ...[
              _action(
                icon: Icons.bookmark_border,
                title:
                    'Enregistrer la position pour une utilisation ultérieure',
                onTap: _save,
              ),
              _action(
                icon: Icons.search,
                title: 'Modifier votre position / Rechercher',
                onTap: _search,
              ),
              _action(
                icon: Icons.ios_share_outlined,
                title: 'Partager la position',
                onTap: _share,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.darkText),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.lightText),
      onTap: onTap,
    );
  }
}
