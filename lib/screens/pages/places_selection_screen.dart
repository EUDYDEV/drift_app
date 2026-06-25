import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class PlacesSelectionScreen extends StatefulWidget {
  final String activityType;
  final Color activityColor;
  final Map<String, dynamic> activityData;

  const PlacesSelectionScreen({
    super.key,
    required this.activityType,
    required this.activityColor,
    required this.activityData,
  });

  @override
  State<PlacesSelectionScreen> createState() => _PlacesSelectionScreenState();
}

class _PlacesSelectionScreenState extends State<PlacesSelectionScreen> {
  final List<Map<String, dynamic>> _selectedPlaces = [];
  double _totalBudget = 0;

  @override
  Widget build(BuildContext context) {
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
          'Sélectionnez vos lieux',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Budget info
          _buildBudgetInfo(),
          // Places list
          Expanded(
            child: _buildPlacesList(),
          ),
          // Bottom bar with selected items
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBudgetInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.activityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.activityColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: widget.activityColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget disponible',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ),
                Text(
                  '${widget.activityData['budget'] ?? 'Non défini'} FCFA',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.activityColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Dépensé',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ),
              Text(
                '$_totalBudget FCFA',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildPlaceCard(
          name: 'Hôtel Sofitel Abidjan',
          image: 'https://via.placeholder.com/400x200',
          price: 85000,
          rating: 4.8,
          location: 'Plateau',
          description: 'Hôtel 5 étoiles avec vue sur la lagune',
        ),
        const SizedBox(height: 16),
        _buildPlaceCard(
          name: 'Radisson Blu Abidjan',
          image: 'https://via.placeholder.com/400x200',
          price: 75000,
          rating: 4.6,
          location: 'Cocody',
          description: 'Hôtel de luxe avec piscine et spa',
        ),
        const SizedBox(height: 16),
        _buildPlaceCard(
          name: 'Onomo Hotel Abidjan',
          image: 'https://via.placeholder.com/400x200',
          price: 45000,
          rating: 4.3,
          location: 'Marcory',
          description: 'Hôtel moderne et confortable',
        ),
        const SizedBox(height: 16),
        _buildPlaceCard(
          name: 'Novotel Abidjan',
          image: 'https://via.placeholder.com/400x200',
          price: 55000,
          rating: 4.5,
          location: 'Plateau',
          description: 'Hôtel international au cœur de la ville',
        ),
        const SizedBox(height: 16),
        _buildPlaceCard(
          name: 'Hotel Ivoire',
          image: 'https://via.placeholder.com/400x200',
          price: 65000,
          rating: 4.4,
          location: 'Plateau',
          description: 'Hôtel historique avec casino',
        ),
      ],
    );
  }

  Widget _buildPlaceCard({
    required String name,
    required String image,
    required double price,
    required double rating,
    required String location,
    required String description,
  }) {
    final isSelected = _selectedPlaces.any((place) => place['name'] == name);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? widget.activityColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: Stack(
                children: [
                  // Placeholder for image
                  Center(
                    child: Icon(Icons.hotel, size: 50, color: Colors.grey[400]),
                  ),
                  // Rating badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and location
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${price.toInt()} FCFA',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.activityColor,
                          ),
                        ),
                        Text(
                          '/nuit',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                // Add to pack button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _togglePlaceSelection(
                        name: name,
                        image: image,
                        price: price,
                        rating: rating,
                        location: location,
                        description: description,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.grey[400] : widget.activityColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSelected ? 'Retirer du pack' : 'Ajouter au pack',
                      style: GoogleFonts.montserrat(
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

  void _togglePlaceSelection({
    required String name,
    required String image,
    required double price,
    required double rating,
    required String location,
    required String description,
  }) {
    setState(() {
      final existingIndex =
          _selectedPlaces.indexWhere((place) => place['name'] == name);

      if (existingIndex != -1) {
        // Remove from selection
        _selectedPlaces.removeAt(existingIndex);
        _totalBudget -= price;
      } else {
        // Add to selection
        _selectedPlaces.add({
          'name': name,
          'image': image,
          'price': price,
          'rating': rating,
          'location': location,
          'description': description,
        });
        _totalBudget += price;
      }
    });
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected items count
            if (_selectedPlaces.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag, color: widget.activityColor),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedPlaces.length} lieu(s) sélectionné(s)',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: $_totalBudget FCFA',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.activityColor,
                      ),
                    ),
                  ],
                ),
              ),
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPlaces.isEmpty ? null : _continueToPack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPlaces.isEmpty
                      ? Colors.grey[300]
                      : widget.activityColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continuer vers le pack',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToPack() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackConfirmationScreen(
          activityType: widget.activityType,
          activityColor: widget.activityColor,
          activityData: widget.activityData,
          selectedPlaces: _selectedPlaces,
          totalBudget: _totalBudget,
        ),
      ),
    );
  }
}

class PackConfirmationScreen extends StatefulWidget {
  final String activityType;
  final Color activityColor;
  final Map<String, dynamic> activityData;
  final List<Map<String, dynamic>> selectedPlaces;
  final double totalBudget;

  const PackConfirmationScreen({
    super.key,
    required this.activityType,
    required this.activityColor,
    required this.activityData,
    required this.selectedPlaces,
    required this.totalBudget,
  });

  @override
  State<PackConfirmationScreen> createState() => _PackConfirmationScreenState();
}

class _PackConfirmationScreenState extends State<PackConfirmationScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _needDriver = false;

  @override
  Widget build(BuildContext context) {
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
          'Confirmer votre pack',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity summary
            _buildActivitySummary(),
            const SizedBox(height: 24),
            // Selected places
            _buildSelectedPlaces(),
            const SizedBox(height: 24),
            // Date and time selection
            _buildDateTimeSelection(),
            const SizedBox(height: 24),
            // Driver option
            _buildDriverOption(),
            const SizedBox(height: 32),
            // Confirm button
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.activityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.activityColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité: ${widget.activityType}',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.activityColor,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.activityData['duration'] != null)
            Text(
              'Durée: ${widget.activityData['duration']}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.grayText,
              ),
            ),
          if (widget.activityData['destination'] != null)
            Text(
              'Destination: ${widget.activityData['destination']}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.grayText,
              ),
            ),
          if (widget.activityData['travelType'] != null)
            Text(
              'Type: ${widget.activityData['travelType']}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.grayText,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlaces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lieux sélectionnés',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.selectedPlaces.map((place) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.hotel, color: widget.activityColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name'],
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        place['location'],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${place['price'].toInt()} FCFA',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.activityColor,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.activityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total du pack',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                '${widget.totalBudget.toInt()} FCFA',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.activityColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date et heure de début',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: widget.activityColor),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Sélectionner une date',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? AppColors.darkText
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: widget.activityColor),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime != null
                            ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Sélectionner l\'heure',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: _selectedTime != null
                              ? AppColors.darkText
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transport',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            setState(() => _needDriver = !_needDriver);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _needDriver
                  ? widget.activityColor.withValues(alpha: 0.1)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _needDriver ? widget.activityColor : Colors.grey[300]!,
                width: _needDriver ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: widget.activityColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Besoin d\'un chauffeur',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'Un chauffeur viendra vous chercher à temps',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color:
                        _needDriver ? widget.activityColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _needDriver
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedDate == null || _selectedTime == null
            ? null
            : _confirmReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedDate == null || _selectedTime == null
              ? Colors.grey[300]
              : widget.activityColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Confirmer la réservation',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _confirmReservation() async {
    // Simulation d'un appel API au backend Rust pour enregistrer le pack voyage
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: widget.activityColor),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context); // Fermer l'indicateur de chargement

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réservation confirmée avec succès!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
