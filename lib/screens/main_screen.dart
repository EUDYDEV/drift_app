import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/cart_model.dart';
import 'pages/explorer_page.dart';
import 'pages/chauffeur_page.dart';
import 'pages/voyages_page.dart';
import 'pages/lieux_page.dart';
import 'panier_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    ExplorerPage(),
    ChauffeurPage(),
    VoyagesPage(),
    LieuxPage(),
    PanierPage(),
  ];

  @override
  void initState() {
    super.initState();
    CartModel.itemCount.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CartModel.itemCount.removeListener(_onCartChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildFloatingNav(context),
    );
  }

  Widget _buildFloatingNav(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: bottom + 10,
        top: 6,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.88),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.grey.withValues(alpha:0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.explore_outlined, Icons.explore, 'Explorer'),
                _navItem(1, Icons.directions_car_outlined, Icons.directions_car, 'Chauffeur'),
                _navItem(2, Icons.calendar_month_outlined, Icons.calendar_month, 'Voyages'),
                _navItem(3, Icons.favorite_border, Icons.favorite, 'Lieux'),
                _cartNavItem(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData outlined, IconData filled, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => AppColors.blueViolet.createShader(b),
                child: Icon(filled, size: 23, color: Colors.white),
              )
            else
              Icon(outlined, size: 23, color: Colors.grey[400]),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.gradientBlue : Colors.grey[400],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              margin: const EdgeInsets.only(top: 2),
              height: 2,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.blueViolet : null,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icône Panier avec badge dynamique
  Widget _cartNavItem() {
    final isActive = _currentIndex == 4;
    final count = CartModel.itemCount.value;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 4),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (isActive)
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) =>
                        AppColors.blueViolet.createShader(b),
                    child: const Icon(Icons.shopping_bag,
                        size: 23, color: Colors.white),
                  )
                else
                  Icon(Icons.shopping_bag_outlined,
                      size: 23, color: Colors.grey[400]),
                // Badge count
                if (count > 0)
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Panier',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.gradientBlue : Colors.grey[400],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              margin: const EdgeInsets.only(top: 2),
              height: 2,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.blueViolet : null,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
