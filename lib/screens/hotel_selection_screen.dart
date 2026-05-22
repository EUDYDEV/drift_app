import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hotel_model.dart'; // This now defines 'Hotel'
import '../models/room_model.dart'; // This defines 'Room'
import '../services/hotel_service.dart';
import '../theme/app_colors.dart';
import 'booking_summary_screen.dart';

class HotelSelectionScreen extends StatefulWidget {
  final Hotel hotel;
  final String city;

  const HotelSelectionScreen({
    super.key,
    required this.hotel,
    required this.city,
  });

  @override
  State<HotelSelectionScreen> createState() => _HotelSelectionScreenState();
}

class _HotelSelectionScreenState extends State<HotelSelectionScreen> {
  late HotelService _hotelService;
  List<Room> _rooms = [];
  bool _isLoading = true;
  final Map<String, int> _selectedRooms = {}; // roomId -> quantity
  double _totalPrice = 0;
  
  // Gestion flexible des dates
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));

  @override
  void initState() {
    super.initState();
    _hotelService = HotelService();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await _hotelService.getRoomsForHotel(widget.hotel.id);
      if (mounted) {
        setState(() {
          _rooms = rooms;
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

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
    );
    if (picked != null) {
      setState(() {
        _checkIn = picked.start;
        _checkOut = picked.end;
        _calculateTotal();
      });
    }
  }

  void _toggleRoom(String roomId, int quantity) {
    setState(() {
      if (quantity > 0) {
        _selectedRooms[roomId] = quantity;
      } else {
        _selectedRooms.remove(roomId);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0;
    final nights = _checkOut.difference(_checkIn).inDays;
    final actualNights = nights > 0 ? nights : 1;

    _selectedRooms.forEach((roomId, quantity) {
      final room = _rooms.firstWhere((r) => r.id == roomId);
      total += room.price * quantity * actualNights;
    });

    _totalPrice = total;
  }

  void _proceedToBooking() {
    if (_selectedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner au moins une chambre')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSummaryScreen(
          hotel: widget.hotel,
          departureDate: _checkIn,
          returnDate: _checkOut,
          selectedRooms: _selectedRooms,
          totalPrice: _totalPrice,
          city: widget.city,
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
    final nights = _checkOut.difference(_checkIn).inDays;
    final displayNights = nights > 0 ? nights : 1;
    
    // Détermination dynamique des labels
    final String type = widget.hotel.type;
    final bool isHotel = type == 'hotel';
    final bool isRestau = type == 'restaurant';
    
    final String sectionTitle = isHotel ? 'Chambres disponibles' : (isRestau ? 'Tables disponibles' : 'Séances disponibles');
    final String unitLabel = isHotel ? 'nuit' : (isRestau ? 'réservation' : 'billet');
    final String tourLabel = isHotel ? 'Visiter la chambre (3D)' : (isRestau ? 'Voir la table et la vue (3D)' : 'Voir la salle (3D)');
    final String emptyLabel = isHotel ? 'Aucune chambre disponible' : 'Aucune table disponible';

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
          widget.hotel.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00B894),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION DATES FLEXIBLES
                        _buildSectionTitle('Votre séjour'),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _selectDateRange,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color:
                                      AppColors.gradientBlue.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: AppColors.gradientBlue),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Du ${_checkIn.day}/${_checkIn.month} au ${_checkOut.day}/${_checkOut.month}',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        '$displayNights nuit(s) sélectionnée(s)',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.grayText),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit,
                                    size: 18, color: AppColors.grayText),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // CHAMBRES
                        _buildSectionTitle(sectionTitle),
                        const SizedBox(height: 12),

                        if (_rooms.isEmpty)
                          Center(
                            child: Text(
                              emptyLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        else
                          ..._rooms
                              .map((room) => _buildRoomCard(room, displayNights, unitLabel, tourLabel)),
                      ],
                    ),
                  ),
                ),
                // FOOTER AVEC TOTAL ET BUTTON
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_totalPrice.toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00B894),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: _proceedToBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B894),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Continuer',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );
  }

  Widget _buildRoomCard(Room room, int nights, String unitLabel, String tourLabel) {
    final quantity = _selectedRooms[room.id] ?? 0;
    final totalForThisRoom = room.price * quantity * nights;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PHOTO DE LA CHAMBRE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(Icons.hotel, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.roomType,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capacité : ${room.capacity} personne${room.capacity > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${room.price.toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00B894),
                    ),
                  ),
                  Text(
                    'par $unitLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AMENITIES
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: room.amenities
                .map(
                  (amenity) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      amenity,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),

           // VISITE VIRTUELLE (NOUVEAUTÉ)
           if (room.virtualTourUrl != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: InkWell(
                 onTap: () {
                   // Ouvre une boîte de dialogue dédiée à la visite 360°
                   showDialog(
                     context: context,
                     builder: (_) => Dialog(
                       backgroundColor: Colors.black,
                       child: Padding(
                         padding: const EdgeInsets.all(16),
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Icon(Icons.threed_rotation, size: 48, color: Colors.blue),
                             const SizedBox(height: 16),
                             Text(
                               'Visite 360°',
                               style: GoogleFonts.montserrat(
                                 fontSize: 20,
                                 fontWeight: FontWeight.w900,
                                 color: Colors.white,
                               ),
                             ),
                             const SizedBox(height: 16),
                             Text(
                               'Cette fonctionnalité sera bientôt disponible avec une visite immersive à 360°.\\n'
                               'Pour l\'instant, voici un aperçu de la chambre.',
                               textAlign: TextAlign.center,
                               style: GoogleFonts.montserrat(
                                 color: Colors.white70,
                               ),
                             ),
                             const SizedBox(height: 24),
                             GestureDetector(
                               onTap: () => Navigator.pop(context),
                               child: Container(
                                 width: double.infinity,
                                 padding: const EdgeInsets.symmetric(vertical: 12),
                                 decoration: BoxDecoration(
                                   color: AppColors.gradientBlue,
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 child: Text(
                                   'Fermer',
                                   textAlign: TextAlign.center,
                                   style: GoogleFonts.montserrat(
                                     color: Colors.white,
                                     fontWeight: FontWeight.w800,
                                   ),
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                   );
                 },
                 child: Row(
                   children: [
                     const Icon(Icons.threed_rotation, color: Color(0xFF1E90FF), size: 18),
                     const SizedBox(width: 8),
                     Text(
                       tourLabel,
                       style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E90FF)),
                     ),
                   ],
                 ),
               ),
             ),

          // QUANTITY SELECTOR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantité: $quantity',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: quantity > 0
                        ? () => _toggleRoom(room.id, quantity - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle),
                    color: const Color(0xFF00B894),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 22,
                  ),
                  IconButton(
                    onPressed: () => _toggleRoom(room.id, quantity + 1),
                    icon: const Icon(Icons.add_circle),
                    color: const Color(0xFF00B894),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 22,
                  ),
                ],
              ),
            ],
          ),

          if (quantity > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: ${totalForThisRoom.toStringAsFixed(0)} FCFA ($quantity x $nights nuit${nights > 1 ? 's' : ''})',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00B894),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
