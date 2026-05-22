import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/cart_model.dart';

class LieuxPage extends StatelessWidget {
  const LieuxPage({super.key});

  static final List<_PlaceData> _places = [
    const _PlaceData(
      name: 'Le Wafou',
      address: 'Cocody Riviera, Abidjan',
      type: 'Restaurant',
      icon: Icons.restaurant,
      savedLabel: 'Table Sauvée',
      rating: 4.8,
      color: AppColors.gradientBlue,
    ),
    const _PlaceData(
      name: 'Hôtel Ivoire',
      address: 'Cocody, Abidjan',
      type: 'Hôtel',
      icon: Icons.hotel,
      savedLabel: 'Chambre Favorite',
      rating: 4.9,
      color: AppColors.gradientPurple,
    ),
    const _PlaceData(
      name: 'La Palm Beach',
      address: 'Assinie-Mafia',
      type: 'Plage & Resort',
      icon: Icons.beach_access,
      savedLabel: 'Lieu Favori',
      rating: 4.7,
      color: AppColors.orange,
    ),
    const _PlaceData(
      name: 'Café de la Paix',
      address: 'Plateau, Abidjan',
      type: 'Café',
      icon: Icons.local_cafe,
      savedLabel: 'Commande Habituelle',
      rating: 4.5,
      color: Color(0xFF11998E),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildPlaceCard(context, _places[i]),
                  childCount: _places.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIEUX FAVORIS',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vos lieux & expériences préférés',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.grayText,
            ),
          ),
          const SizedBox(height: 16),
          // Compteur
          Row(
            children: [
              _chip('${_places.length} lieux', Icons.favorite, Colors.red),
              const SizedBox(width: 10),
              _chip('Tous sauvegardés', Icons.cloud_done_outlined,
                  AppColors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, _PlaceData place) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête de la carte
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Miniature circulaire
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: place.color.withValues(alpha:0.12),
                    border: Border.all(
                      color: place.color.withValues(alpha:0.28),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(place.icon, color: place.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 18),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppColors.grayText, size: 12),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              place.address,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: AppColors.grayText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: place.color.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          place.type,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: place.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bloc de détails
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  place.savedLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const Spacer(),
                _starRating(place.rating),
                const SizedBox(width: 4),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),

          // Actions + Bouton réserver
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _iconAction(Icons.phone_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Simulation : Appel en cours...'),
                        duration: Duration(seconds: 1)),
                  );
                }),
                const SizedBox(width: 8),
                _iconAction(Icons.navigation_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Simulation : Ouverture de l\'itinéraire...'),
                        duration: Duration(seconds: 1)),
                  );
                }),
                const SizedBox(width: 8),
                _iconAction(Icons.share_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Simulation : Menu de partage...'),
                        duration: Duration(seconds: 1)),
                  );
                }),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    // Simulation d'ajout au panier front-end
                    CartModel.add(CartItem(
                      id: 'lieu_${place.name.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                      type: 'lieu',
                      name: place.name,
                      subtitle: place.type,
                      priceDisplay: 'Sur devis',
                      priceValue: 0,
                      color: place.color,
                      icon: place.icon,
                    ));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${place.name} a été ajouté à votre panier !',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppColors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha:0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Réserver',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _starRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 12);
        } else if (i < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 12);
        }
        return const Icon(Icons.star_border, color: Colors.amber, size: 12);
      }),
    );
  }

  Widget _iconAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.darkText),
      ),
    );
  }
}

class _PlaceData {
  final String name;
  final String address;
  final String type;
  final IconData icon;
  final String savedLabel;
  final double rating;
  final Color color;

  const _PlaceData({
    required this.name,
    required this.address,
    required this.type,
    required this.icon,
    required this.savedLabel,
    required this.rating,
    required this.color,
  });
}
