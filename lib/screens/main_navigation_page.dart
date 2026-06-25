import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/main_navigation_controller.dart';
import '../models/cart_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_header.dart';
import 'home_screen.dart';
import 'menu/profile_page.dart';
import 'pages/discovery_page.dart';
import 'pages/voyages_page.dart';
import 'panier_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late final MainNavigationController _navigationController;
  int _currentIndex = 0;

  final List<Widget> _pages = const <Widget>[
    HomeScreen(),
    DiscoveryPage(),
    VoyagesPage(),
    PanierPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _navigationController = context.read<MainNavigationController>();
    _currentIndex = _navigationController.currentIndex;
    _navigationController.addListener(_onNavigationChanged);
    CartModel.itemCount.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onNavigationChanged() {
    if (!mounted) return;
    setState(() {
      _currentIndex = _navigationController.currentIndex;
    });
  }

  @override
  void dispose() {
    _navigationController.removeListener(_onNavigationChanged);
    CartModel.itemCount.removeListener(_onCartChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      extendBody: true,
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: _buildNav(context),
    );
  }

  Widget _buildNav(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 14, right: 14, bottom: bottom + 10, top: 6),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                MainNavigationController.homeIndex,
                Icons.explore_outlined,
                Icons.explore,
                'Accueil',
              ),
            ),
            Expanded(
              child: _navItem(
                MainNavigationController.experiencesIndex,
                Icons.auto_awesome_outlined,
                Icons.auto_awesome,
                'Experiences',
              ),
            ),
            Expanded(
              child: _navItem(
                MainNavigationController.voyagesIndex,
                Icons.event_available_outlined,
                Icons.event_available,
                'Activites',
              ),
            ),
            Expanded(child: _cartItem()),
            Expanded(
              child: _navItem(
                MainNavigationController.profileIndex,
                Icons.person_outline,
                Icons.person,
                'Profil',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData outlined, IconData filled, String label) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => _navigationController.goTo(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            active
                ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppColors.blueViolet.createShader(bounds),
                    child: Icon(filled, size: 23, color: Colors.white),
                  )
                : Icon(outlined, size: 23, color: Colors.grey[400]),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.gradientBlue : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartItem() {
    final active = _currentIndex == MainNavigationController.packIndex;
    final count = CartModel.itemCount.value;

    return GestureDetector(
      onTap: () => _navigationController.goTo(MainNavigationController.packIndex),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              active
                  ? ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          AppColors.blueViolet.createShader(bounds),
                      child: const Icon(
                        Icons.shopping_bag,
                        size: 23,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.shopping_bag_outlined,
                      size: 23,
                      color: Colors.grey[400],
                    ),
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
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Pack',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.gradientBlue : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
