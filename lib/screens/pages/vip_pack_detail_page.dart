import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/vip_packs_data.dart';
import '../../models/cart_model.dart';
import '../../theme/app_colors.dart';

class VipPackDetailPage extends StatelessWidget {
  final VipPack pack;
  const VipPackDetailPage({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context),
            const SizedBox(height: 28),
            _buildGiftsSection(),
            const SizedBox(height: 32),
            _buildReserveButton(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: 32,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pack.gradientStart.withValues(alpha:0.25),
            const Color(0xFF141414),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [pack.gradientStart, pack.gradientEnd]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pack.tag,
              style: GoogleFonts.montserrat(
                color: Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            pack.name,
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            pack.subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha:0.12)),
            ),
            child: Text(
              pack.price,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [pack.gradientStart, pack.gradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ce que vous recevez',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...pack.gifts.asMap().entries.map((e) => _buildGiftTile(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildGiftTile(int index, VipGift gift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [pack.gradientStart, pack.gradientEnd]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(gift.icon, color: Colors.black87, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gift.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [pack.gradientStart, pack.gradientEnd]),
            ),
            child: const Icon(Icons.check, color: Colors.black87, size: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          CartModel.add(CartItem(
            id: '${pack.id}_${DateTime.now().millisecondsSinceEpoch}',
            type: 'pack',
            name: pack.name,
            subtitle: 'Pack VIP · ${pack.gifts.length} avantages inclus',
            priceDisplay: pack.price,
            priceValue: pack.priceValue,
            color: pack.gradientStart,
            icon: Icons.star,
          ));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${pack.name} ajouté au panier !',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.green,
          ));
          Navigator.pop(context);
        },
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [pack.gradientStart, pack.gradientEnd]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: pack.gradientStart.withValues(alpha:0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'RÉSERVER CE PACK',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
