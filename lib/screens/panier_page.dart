import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/pack_journey_controller.dart';
import '../theme/app_colors.dart';
import '../models/cart_model.dart';
import '../widgets/pack_configurator_panel.dart';
import 'paiement_page.dart';

class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  @override
  void initState() {
    super.initState();
    CartModel.itemCount.addListener(_rebuild);
    CartModel.revision.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CartModel.itemCount.removeListener(_rebuild);
    CartModel.revision.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PackJourneyController>();
    final items = CartModel.items;
    final single = items.length == 1;
    final shortActivity = _shortActivity(items);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(items.length),
            Expanded(
              child: items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        const PackConfiguratorPanel(),
                        SizedBox(height: 280, child: _buildEmpty()),
                      ],
                    )
                  : Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.only(bottom: 180),
                          children: [
                            const PackConfiguratorPanel(),
                            if (shortActivity != null)
                              _buildAiSuggestionsBanner(shortActivity),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  ...items.map((item) => _buildCartCard(item)),
                                  const SizedBox(height: 12),
                                  _buildTotalBlock(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: _buildActions(context, single),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  CartItem? _shortActivity(List<CartItem> items) {
    if (items.length != 1) return null;
    final item = items.first;
    final duration = (item.metadata['durationMinutes'] as num?)?.toInt() ??
        (item.metadata['duration_minutes'] as num?)?.toInt();
    final isActivity = item.type == 'activity' ||
        item.serviceType == 'ticket_jeu' ||
        item.serviceType == 'ticket_cinema';
    if (!isActivity || (duration != null && duration > 180)) return null;
    return item;
  }

  Widget _buildAiSuggestionsBanner(CartItem activity) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.orange, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drift IA : Optimisez le reste de votre journée',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Votre activité est courte. Ces idées près de ${activity.partnerCity ?? 'votre destination'} sont libres et n’imposent aucun budget global.',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: AppColors.grayText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _aiSuggestionRow(
            icon: Icons.restaurant_outlined,
            label: 'Restaurant local pour midi',
            price: 12000,
            type: 'restaurant',
          ),
          const SizedBox(height: 8),
          _aiSuggestionRow(
            icon: Icons.nightlife_outlined,
            label: 'Lounge calme en soirée',
            price: 18000,
            type: 'activity',
          ),
        ],
      ),
    );
  }

  Widget _aiSuggestionRow({
    required IconData icon,
    required String label,
    required int price,
    required String type,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.darkText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label · ${CartModel.formatCurrency(price)}',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Ajouter au panier',
          onPressed: () {
            CartModel.add(
              CartItem(
                id: 'ai-$type-${DateTime.now().millisecondsSinceEpoch}',
                type: type,
                name: label,
                subtitle: 'Suggestion libre Drift IA',
                priceDisplay: CartModel.formatCurrency(price),
                priceValue: price,
                color: AppColors.orange,
                icon: icon,
                metadata: const <String, dynamic>{'source': 'drift_ai'},
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label ajouté au panier')),
            );
          },
          icon: const Icon(Icons.add_circle, color: AppColors.orange),
        ),
      ],
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(int count) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child:
                const Icon(Icons.shopping_bag, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOS SÉLECTIONS',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$count élément${count > 1 ? 's' : ''} sélectionné${count > 1 ? 's' : ''}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (CartModel.items.isNotEmpty)
            GestureDetector(
              onTap: () {
                CartModel.clear();
                setState(() {});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Vider',
                  style: GoogleFonts.montserrat(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Carte item du panier ─────────────────────────────────────────────────
  Widget _buildCartCard(CartItem item) {
    final typeLabel = {
          'hotel': 'Hôtel',
          'chauffeur': 'Chauffeur',
          'restaurant': 'Restaurant',
        }[item.type] ??
        item.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône type
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: item.color.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: item.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AppColors.grayText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.priceDisplay,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
            // Supprimer
            GestureDetector(
              onTap: () => CartModel.remove(item.id),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bloc total ───────────────────────────────────────────────────────────
  Widget _buildTotalBlock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          ...CartModel.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    item.priceDisplay,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL COMBINÉ',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => const LinearGradient(
                  colors: [AppColors.orange, Color(0xFFFFB347)],
                ).createShader(b),
                child: Text(
                  CartModel.totalFormatted,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Boutons d'action ─────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context, bool single) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Confirmer et Payer Tout
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaiementPage(items: List.from(CartModel.items)),
            ),
          ),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Confirmer et Payer Tout',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Réserver Seul (actif uniquement si 1 élément)
        GestureDetector(
          onTap: single
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PaiementPage(items: [CartModel.items.first]),
                    ),
                  )
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            decoration: BoxDecoration(
              color: single
                  ? AppColors.gradientBlue.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: single
                    ? AppColors.gradientBlue.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'Réserver Seul',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: single ? AppColors.gradientBlue : AppColors.lightText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Panier vide ──────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 72, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Votre panier est vide',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explorez nos hôtels et ajoutez\nvos favoris au panier',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.grayText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
