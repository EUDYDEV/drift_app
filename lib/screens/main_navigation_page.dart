import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/cart_model.dart';
import 'home_screen.dart';
import 'pages/discovery_page.dart'; // Import de la nouvelle page
import 'pages/voyages_page.dart';
import 'panier_page.dart';
import 'menu/profile_page.dart';
import '../widgets/custom_header.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const DiscoveryPage(), // Remplacement de ChauffeurPage par DiscoveryPage
    const VoyagesPage(),
    const PanierPage(),
    const ProfilePage(),
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
      body: Column(
        children: [
          const CustomHeader(), // Le header global !
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
      padding:
          EdgeInsets.only(left: 14, right: 14, bottom: bottom + 10, top: 6),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.withValues(alpha:0.12)),
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
            _navItem(1, Icons.hotel_outlined, Icons.hotel,
                'Hôtels'), // Transformé de Chauffeur à Hôtels
            _navItem(2, Icons.history_outlined, Icons.history,
                'Activités'), // Renommé de Voyages à Activités
            _cartItem(),
            _navItem(4, Icons.person_outline, Icons.person, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData outlined, IconData filled, String label) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
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
                    shaderCallback: (b) => AppColors.blueViolet.createShader(b),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 2),
              height: 2,
              width: active ? 20 : 0,
              decoration: BoxDecoration(
                gradient: active ? AppColors.blueViolet : null,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartItem() {
    final active = _currentIndex == 3;
    final count = CartModel.itemCount.value;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 3),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                active
                    ? ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) =>
                            AppColors.blueViolet.createShader(b),
                        child: const Icon(Icons.shopping_bag,
                            size: 23, color: Colors.white),
                      )
                    : Icon(Icons.shopping_bag_outlined,
                        size: 23, color: Colors.grey[400]),
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
                          count > 9 ? '9+' : '$count',
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
              'Pack',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.gradientBlue : Colors.grey[400],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 2),
              height: 2,
              width: active ? 20 : 0,
              decoration: BoxDecoration(
                gradient: active ? AppColors.blueViolet : null,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
