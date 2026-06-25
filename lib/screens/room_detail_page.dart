import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/room_model.dart';
import '../theme/app_colors.dart';

class RoomDetailPage extends StatelessWidget {
  final Room room;

  const RoomDetailPage({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          room.roomType,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Aperçu Premium', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${room.price.toStringAsFixed(0)} FCFA', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF00B894))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildIconInfo(Icons.people_outline, 'Capacité : ${room.capacity} personnes'),
                  const SizedBox(height: 12),
                  _buildIconInfo(Icons.square_foot, 'Superficie : 42 m²'),
                  const SizedBox(height: 30),
                  Text('Équipements', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: room.amenities.map((a) => _buildBadge(a)).toList(),
                  ),
                  const SizedBox(height: 30),
                  Text('Description', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    'Profitez d\'un confort absolu dans cette ${room.roomType.toLowerCase()}. '
                    'Équipée de matériaux nobles et d\'une literie haut de gamme, elle est idéale pour vos séjours d\'affaires ou de détente.',
                    style: GoogleFonts.poppins(color: Colors.grey[700], height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 20, color: AppColors.gradientBlue), const SizedBox(width: 12), Text(text)]);
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
