import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hotel_model.dart'; // This now defines 'Hotel'
// import '../models/room_model.dart'; // Not directly used here
import '../services/hotel_service.dart';
import '../theme/app_colors.dart';
import 'hotel_selection_screen.dart';

class ReservationDateScreen extends StatefulWidget {
  final String city;
  final DateTime departureDate;
  final DateTime? returnDate;

  const ReservationDateScreen({
    super.key,
    required this.city,
    required this.departureDate,
    this.returnDate,
  });

  @override
  State<ReservationDateScreen> createState() => _ReservationDateScreenState();
}

class _ReservationDateScreenState extends State<ReservationDateScreen> {
  late HotelService _hotelService;
  List<Hotel> _hotels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _hotelService = HotelService();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    try {
      final hotels = await _hotelService.getHotelsInCity(widget.city);
      if (mounted) {
        setState(() {
          _hotels = hotels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _selectHotel(Hotel hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelSelectionScreen(
          hotel: hotel,
          city: widget.city, // Passage de la ville requis par l'écran
          onBack: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hotelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nights = widget.returnDate == null
        ? 1
        : widget.returnDate!.difference(widget.departureDate).inDays;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choisissez un hôtel',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00B894),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RÉSUMÉ DE LA RÉSERVATION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.city,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.departureDate.day}/${widget.departureDate.month} - ${widget.returnDate?.day ?? widget.departureDate.day}/${widget.returnDate?.month ?? widget.departureDate.month}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber[300]!),
                        ),
                        child: Text(
                          '$nights nuit${nights > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // LISTE HÔTELS
            Text(
              'Hôtels disponibles (${_hotels.length})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            if (_hotels.isEmpty)
              Center(
                child: Text(
                  'Aucun hôtel disponible',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              ..._hotels.map((hotel) => _buildHotelCard(hotel, nights)),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel, int nights) {
    final totalPrice = hotel.pricePerNight * nights;

    return GestureDetector(
      onTap: () => _selectHotel(hotel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${hotel.rating} (${hotel.reviewCount} avis)',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalPrice.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00B894),
                        ),
                      ),
                      Text(
                        'pour $nights nuit${nights > 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // DESCRIPTION
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // AMENITIES
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotel.amenities
                        .take(3)
                        .map(
                          (amenity) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          amenity,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _selectHotel(hotel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Voir les chambres',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
      ),
    );
  }
}