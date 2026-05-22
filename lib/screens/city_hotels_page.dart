import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../data/hotels_data.dart';
import '../models/hotel_model.dart';
import 'hotel_detail_page.dart';

class CityHotelsPage extends StatelessWidget {
  final String city;
  const CityHotelsPage({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final hotels = getHotelsByCity(city);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: hotels.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    itemCount: hotels.length,
                    itemBuilder: (_, i) => _buildHotelCard(context, hotels[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha:0.1),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hôtels à $city',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${getHotelsByCity(city).length} établissements disponibles',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha:0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.tune, color: Colors.white70, size: 22),
        ],
      ),
    );
  }

  Widget _buildHotelCard(BuildContext context, HotelModel hotel) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: hotel)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: Stack(
                children: [
                  Image.network(
                    hotel.imageSeeds[0],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: AppColors.lightGray,
                      child: const Center(
                          child: Icon(Icons.hotel, size: 50, color: AppColors.lightText)),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            hotel.rating.toString(),
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hotel.category,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.location_on,
                              color: AppColors.grayText, size: 12),
                          const SizedBox(width: 2),
                          Text(hotel.location,
                              style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: AppColors.grayText)),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          hotel.priceDisplay,
                          style: GoogleFonts.montserrat(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.blueViolet,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Voir',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child:
                const Icon(Icons.hotel, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun hôtel pour $city',
            style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grayText),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez bientôt !',
            style: GoogleFonts.montserrat(
                fontSize: 13, color: AppColors.lightText),
          ),
        ],
      ),
    );
  }
}
