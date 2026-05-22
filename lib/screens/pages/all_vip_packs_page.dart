import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/vip_packs_data.dart';
import 'vip_pack_detail_page.dart';

class AllVipPacksPage extends StatelessWidget {
  const AllVipPacksPage({super.key});

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
        title: Text(
          'DriFt Expériences VIP',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 72,
          left: 20,
          right: 20,
          bottom: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tous les packs',
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Des expériences uniques, tout inclus.',
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            ...kVipPacks.map((pack) => _buildPackCard(context, pack)),
          ],
        ),
      ),
    );
  }

  Widget _buildPackCard(BuildContext context, VipPack pack) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => VipPackDetailPage(pack: pack)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [pack.gradientStart, pack.gradientEnd]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: pack.gradientStart.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    pack.tag,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${pack.gifts.length} avantages',
                      style: GoogleFonts.montserrat(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.black54),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              pack.name,
              style: GoogleFonts.montserrat(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pack.subtitle,
              style: GoogleFonts.montserrat(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ...pack.gifts.take(4).map((g) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(g.icon, color: Colors.white, size: 16),
                      ),
                    )),
                if (pack.gifts.length > 4)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '+${pack.gifts.length - 4}',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  pack.price,
                  style: GoogleFonts.montserrat(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
