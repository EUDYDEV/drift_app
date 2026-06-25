import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'reservation_date_screen.dart';

class ReservationScreen extends StatefulWidget {
  final String? initialCity;
  final DateTime? initialDepartureDate;
  const ReservationScreen({
    super.key,
    this.initialCity,
    this.initialDepartureDate,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late final TextEditingController _cityController;
  DateTime? _departureDate;
  DateTime? _returnDate;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity);
    _departureDate = widget.initialDepartureDate;
  }

  void _selectDate(bool isDeparture) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = selected;
        } else {
          _returnDate = selected;
        }
      });
    }
  }

  void _proceed() {
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une ville')),
      );
      return;
    }
    if (_departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner une date de départ')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationDateScreen(
          city: _cityController.text,
          departureDate: _departureDate!,
          returnDate: _returnDate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

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
          'Planifier une réservation',
          style: GoogleFonts.poppins(
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
            // INTRO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Réservez votre trajet et votre hôtel en une seule demande',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FORM
            Text(
              'Informations de voyage',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // VILLE
            Text(
              'Quelle ville?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Ex: Yamoussoukro, San Pédro',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // DATE DÉPART
            Text(
              'Quand partez-vous?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildDateButton(
              label: _departureDate == null
                  ? 'Sélectionner la date de départ'
                  : 'Départ: ${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}',
              onTap: () => _selectDate(true),
            ),
            const SizedBox(height: 20),

            // DATE RETOUR (OPTIONNEL)
            Text(
              'Quand revenez-vous? (optionnel)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildDateButton(
              label: _returnDate == null
                  ? 'Sélectionner la date de retour (optionnel)'
                  : 'Retour: ${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}',
              onTap: () => _selectDate(false),
              optional: true,
            ),
            const SizedBox(height: 40),

            // BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continuer',
                  style: GoogleFonts.poppins(
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

  Widget _buildDateButton({
    required String label,
    required VoidCallback onTap,
    bool optional = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.calendar_today, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
