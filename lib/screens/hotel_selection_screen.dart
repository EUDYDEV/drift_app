import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panorama/panorama.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../services/auth_service.dart';
import '../services/hotel_service.dart';
import '../theme/app_colors.dart';
import 'auth/login_screen.dart';

class HotelSelectionScreen extends StatefulWidget {
  final Hotel hotel;
  final String city;
  final VoidCallback onBack;

  const HotelSelectionScreen({
    super.key,
    required this.hotel,
    required this.city,
    required this.onBack,
  });

  @override
  State<HotelSelectionScreen> createState() => _HotelSelectionScreenState();
}

class _HotelSelectionScreenState extends State<HotelSelectionScreen> {
  late final HotelService _hotelService;
  List<RoomModel> _rooms = <RoomModel>[];
  bool _isLoading = true;
  RoomModel? _detailedRoom;

  @override
  void initState() {
    super.initState();
    _hotelService = HotelService();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      if (widget.hotel.rooms.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _rooms = List<RoomModel>.from(widget.hotel.rooms);
          _isLoading = false;
        });
        return;
      }

      final rooms = await _hotelService.getRoomsForHotel(
        widget.hotel.id,
        partnerId: widget.hotel.partnerId,
      );
      if (!mounted) return;
      setState(() {
        _rooms = rooms.cast<RoomModel>();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_detailedRoom != null) {
      return _buildDetailedOffer(_detailedRoom!);
    }

    return Column(
      children: [
        _buildSubHeader(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) =>
                      _buildExperienceCard(_rooms[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSubHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotel.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${widget.city} · Experiences disponibles',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: AppColors.grayText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(RoomModel room) {
    return GestureDetector(
      onTap: () => setState(() => _detailedRoom = room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Image.network(
              room.image ??
                  'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room.roomType,
                          style: GoogleFonts.montserrat(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${room.price.round()} FCFA',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Text(
                        'CLIQUER POUR LES DETAILS',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gradientBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.orange,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedOffer(RoomModel room) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          color: Colors.white,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _detailedRoom = null),
                child: const Icon(Icons.close_rounded, size: 24),
              ),
              const SizedBox(width: 15),
              Text(
                'Details de l\'offre',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showPanoramaDialog(room),
                  child: Image.network(
                    room.image ??
                        'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800',
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomType,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${room.price.round()} FCFA',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (room.virtualTourUrl != null || room.image != null) ...[
                        InkWell(
                          onTap: () => _showPanoramaDialog(room),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.gradientBlue.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.threed_rotation,
                                  color: AppColors.gradientBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Explorer la chambre en 360',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      _detailRow(Icons.people_outline, 'Capacite premium'),
                      _detailRow(
                        Icons.verified_user_outlined,
                        'Service de conciergerie inclus',
                      ),
                      _detailRow(
                        Icons.check_circle_outline_rounded,
                        'Equipements de standing',
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'A propos de cette offre',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Vivez un moment d\'exception dans cet etablissement de prestige. '
                        'Chaque detail a ete soigneusement pense pour garantir votre confort '
                        'et une experience memorable a ${widget.city}.',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppColors.grayText,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _bookingButton(room),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gradientBlue),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingButton(RoomModel room) {
    return InkWell(
      onTap: () {
        if (context.read<AuthService>().isAuthenticated) {
          CartModel.add(
            CartItem(
              id: 'hotel-selection:${room.id}',
              type: 'hotel',
              serviceType: 'chambre_hotel',
              name: widget.hotel.name,
              subtitle: room.roomType,
              priceDisplay: CartModel.formatCurrency(room.price.round()),
              priceValue: room.price.round(),
              color: AppColors.gradientBlue,
              icon: Icons.hotel,
              partnerId: room.partnerId ?? widget.hotel.partnerId,
              prestationId: room.prestationId,
              partnerName: widget.hotel.name,
              partnerType: 'hotel',
              partnerCity: widget.hotel.city,
              partnerAddress: widget.hotel.address,
              partnerLatitude: widget.hotel.latitude,
              partnerLongitude: widget.hotel.longitude,
              metadata: <String, dynamic>{
                'roomId': room.id,
                'roomType': room.roomType,
                'roomCapacity': room.capacity,
                'video360Url': room.virtualTourUrl,
              },
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offre ajoutee a votre pack !')),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'AJOUTER AU PACK',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPanoramaDialog(RoomModel room) async {
    final panoramaUrl = room.virtualTourUrl ?? room.image;
    if (panoramaUrl == null || panoramaUrl.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          height: 360,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Panorama(
                  child: Image.network(
                    panoramaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF101828),
                      child: const Center(
                        child: Icon(
                          Icons.panorama_horizontal,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vue 360° • ${room.roomType}',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
