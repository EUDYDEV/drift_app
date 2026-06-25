import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'menu_drawer.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';
import 'position_actions_bottom_sheet.dart';

class CustomHeader extends StatefulWidget {
  const CustomHeader({super.key});

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  late final LocationService _locationService;
  AppLocation? _currentLocation;

  @override
  void initState() {
    super.initState();
    _locationService = context.read<LocationService>();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() => _currentLocation = location);
    }
  }

  void _openMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => const MenuDrawer(),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openMenu(context),
            child: _buildDriFtIcon(),
          ),
          // Suppression du SizedBox asymétrique ici pour garantir le centrage parfait
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _openMenu(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DriFt',
                        style: GoogleFonts.montserrat(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppColors.blueViolet,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'E-PROJECT',
                          style: GoogleFonts.montserrat(
                            fontSize: 6,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentLocation != null)
                  GestureDetector(
                    onTap: () async {
                      final updated = await showPositionActionsBottomSheet(
                        context: context,
                        currentLocation: _currentLocation!,
                        locationService: _locationService,
                      );
                      if (updated != null && mounted) {
                        setState(() => _currentLocation = updated);
                      }
                    },
                    child: Text(
                      'Ma position',
                      style: GoogleFonts.montserrat(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildGuestIcon(),
        ],
      ),
    );
  }

  Widget _buildDriFtIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/logo.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildGuestIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.lightGray,
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5)),
      child:
          const Icon(Icons.person_outline, color: AppColors.darkText, size: 20),
    );
  }
}
