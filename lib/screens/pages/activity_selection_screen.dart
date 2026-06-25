import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'places_selection_screen.dart';

class ActivitySelectionScreen extends StatefulWidget {
  final String activityType;
  final Color activityColor;

  const ActivitySelectionScreen({
    super.key,
    required this.activityType,
    required this.activityColor,
  });

  @override
  State<ActivitySelectionScreen> createState() =>
      _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  // État du formulaire
  String _selectedDuration = '4-7 jours';
  String _selectedTravelType = 'En famille';
  String _selectedPlaceType = 'Restaurant chic';
  int _selectedPeopleCount = 2;
  final Set<String> _selectedEquipment = {'Système audio', 'Wi-Fi'};

  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
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
          widget.activityType,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planifiez votre ${widget.activityType.toLowerCase()}',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Répondez aux questions pour personnaliser votre expérience',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.grayText,
              ),
            ),
            const SizedBox(height: 32),
            _buildActivityForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityForm() {
    switch (widget.activityType) {
      case 'Vacance':
        return _buildVacationForm();
      case 'Premier rdv':
        return _buildDateForm();
      case 'Voyage d\'affaire':
        return _buildBusinessTripForm();
      case 'Diner gala':
        return _buildGalaDinnerForm();
      case 'Réunion d\'affaire':
        return _buildBusinessMeetingForm();
      case 'Loisirs':
        return _buildLeisureForm();
      case 'Shopping':
        return _buildShoppingForm();
      case 'Événement':
        return _buildEventForm();
      default:
        return _buildGenericForm();
    }
  }

  Widget _buildVacationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Quelle est la durée de vos vacances?'),
        const SizedBox(height: 16),
        _buildDurationSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Où souhaitez-vous aller?'),
        const SizedBox(height: 16),
        _buildDestinationInput(),
        const SizedBox(height: 24),
        _buildQuestion('Type de voyage'),
        const SizedBox(height: 16),
        _buildTravelTypeSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Quel est votre budget?'),
        const SizedBox(height: 16),
        _buildBudgetInput(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildDateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Quel type d\'endroit préférez-vous?'),
        const SizedBox(height: 16),
        _buildPlaceTypeSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Quel est votre budget?'),
        const SizedBox(height: 16),
        _buildBudgetInput(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildBusinessTripForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Quelle est la durée de votre voyage?'),
        const SizedBox(height: 16),
        _buildDurationSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Où se déroule votre voyage d\'affaire?'),
        const SizedBox(height: 16),
        _buildDestinationInput(),
        const SizedBox(height: 24),
        _buildQuestion('Quel est votre budget?'),
        const SizedBox(height: 16),
        _buildBudgetInput(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildGalaDinnerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Quel type de restaurant préférez-vous?'),
        const SizedBox(height: 16),
        _buildRestaurantTypeSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Combien de personnes?'),
        const SizedBox(height: 16),
        _buildPeopleSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Quel est votre budget par personne?'),
        const SizedBox(height: 16),
        _buildBudgetInput(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildBusinessMeetingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Où se déroulera la réunion?'),
        const SizedBox(height: 16),
        _buildDestinationInput(),
        const SizedBox(height: 24),
        _buildQuestion('Combien de participants?'),
        const SizedBox(height: 16),
        _buildPeopleSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Avez-vous besoin d\'équipement spécial?'),
        const SizedBox(height: 16),
        _buildEquipmentSelector(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildLeisureForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Quelle activité souhaitez-vous faire?'),
        const SizedBox(height: 16),
        _buildLeisureActivitySelector(),
        const SizedBox(height: 24),
        _buildQuestion('Où souhaitez-vous aller?'),
        const SizedBox(height: 16),
        _buildDestinationInput(),
        const SizedBox(height: 24),
        _buildQuestion('Quel est votre budget?'),
        const SizedBox(height: 16),
        _buildBudgetInput(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildShoppingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Que souhaitez-vous acheter?'),
        const SizedBox(height: 16),
        _buildShoppingCategorySelector(),
        const SizedBox(height: 24),
        _buildQuestion('Où souhaitez-vous aller?'),
        const SizedBox(height: 16),
        _buildDestinationInput(),
        const SizedBox(height: 24),
        _buildQuestion('Quel est votre budget?'),
        const SizedBox(height: 16),
        _buildBudgetInput(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildEventForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Quel type d\'événement?'),
        const SizedBox(height: 16),
        _buildEventTypeSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Où se déroulera l\'événement?'),
        const SizedBox(height: 16),
        _buildDestinationInput(),
        const SizedBox(height: 24),
        _buildQuestion('Combien de participants?'),
        const SizedBox(height: 16),
        _buildPeopleSelector(),
        const SizedBox(height: 24),
        _buildQuestion('Quel est votre budget?'),
        const SizedBox(height: 16),
        _buildBudgetInput(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildGenericForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestion('Où souhaitez-vous aller?'),
        const SizedBox(height: 16),
        _buildDestinationInput(),
        const SizedBox(height: 24),
        _buildQuestion('Quel est votre budget?'),
        const SizedBox(height: 16),
        _buildBudgetInput(),
        const SizedBox(height: 32),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildQuestion(String question) {
    return Text(
      question,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      children: [
        _durationChip('1 jour', _selectedDuration == '1 jour'),
        const SizedBox(width: 8),
        _durationChip('2-3 jours', _selectedDuration == '2-3 jours'),
        const SizedBox(width: 8),
        _durationChip('4-7 jours', _selectedDuration == '4-7 jours'),
        const SizedBox(width: 8),
        _durationChip(
            'Plus d\'une semaine', _selectedDuration == 'Plus d\'une semaine'),
      ],
    );
  }

  Widget _durationChip(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDuration = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? widget.activityColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? widget.activityColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationInput() {
    return TextField(
      controller: _destinationController,
      decoration: InputDecoration(
        hintText: 'Entrez votre destination',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.activityColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildTravelTypeSelector() {
    return Column(
      children: [
        _travelTypeCard(
            'En couple', Icons.favorite, _selectedTravelType == 'En couple'),
        const SizedBox(height: 12),
        _travelTypeCard('En famille', Icons.family_restroom,
            _selectedTravelType == 'En famille'),
        const SizedBox(height: 12),
        _travelTypeCard(
            'Seul(e)', Icons.person, _selectedTravelType == 'Seul(e)'),
      ],
    );
  }

  Widget _travelTypeCard(String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTravelType = label);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? widget.activityColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? widget.activityColor : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? widget.activityColor : Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? widget.activityColor : AppColors.darkText,
              ),
            ),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: widget.activityColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInput() {
    return TextField(
      controller: _budgetController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Entrez votre budget (FCFA)',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.activityColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceTypeSelector() {
    return Column(
      children: [
        _placeTypeCard('Restaurant chic', Icons.restaurant,
            _selectedPlaceType == 'Restaurant chic'),
        const SizedBox(height: 12),
        _placeTypeCard(
            'Bar lounge', Icons.local_bar, _selectedPlaceType == 'Bar lounge'),
        const SizedBox(height: 12),
        _placeTypeCard('Café romantique', Icons.coffee,
            _selectedPlaceType == 'Café romantique'),
        const SizedBox(height: 12),
        _placeTypeCard(
            'Parc/Jardin', Icons.park, _selectedPlaceType == 'Parc/Jardin'),
      ],
    );
  }

  Widget _placeTypeCard(String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlaceType = label);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? widget.activityColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? widget.activityColor : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? widget.activityColor : Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? widget.activityColor : AppColors.darkText,
              ),
            ),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: widget.activityColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantTypeSelector() {
    return Column(
      children: [
        _placeTypeCard('Restaurant gastronomique', Icons.restaurant,
            _selectedPlaceType == 'Restaurant gastronomique'),
        const SizedBox(height: 12),
        _placeTypeCard('Restaurant international', Icons.public,
            _selectedPlaceType == 'Restaurant international'),
        const SizedBox(height: 12),
        _placeTypeCard('Restaurant local', Icons.location_city,
            _selectedPlaceType == 'Restaurant local'),
      ],
    );
  }

  Widget _buildPeopleSelector() {
    return Row(
      children: List.generate(10, (index) {
        final count = index + 1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedPeopleCount = count);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedPeopleCount == count
                    ? widget.activityColor
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedPeopleCount == count
                      ? widget.activityColor
                      : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedPeopleCount == count
                        ? Colors.white
                        : AppColors.darkText,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEquipmentSelector() {
    return Column(
      children: [
        _equipmentChip('Projecteur', _selectedEquipment.contains('Projecteur')),
        const SizedBox(width: 8),
        _equipmentChip('Écran', _selectedEquipment.contains('Écran')),
        const SizedBox(width: 8),
        _equipmentChip(
            'Système audio', _selectedEquipment.contains('Système audio')),
        const SizedBox(width: 8),
        _equipmentChip('Wi-Fi', _selectedEquipment.contains('Wi-Fi')),
      ],
    );
  }

  Widget _equipmentChip(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedEquipment.contains(label)) {
            _selectedEquipment.remove(label);
          } else {
            _selectedEquipment.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? widget.activityColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? widget.activityColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildLeisureActivitySelector() {
    return Column(
      children: [
        _placeTypeCard(
            'Sport', Icons.sports_soccer, _selectedPlaceType == 'Sport'),
        const SizedBox(height: 12),
        _placeTypeCard(
            'Culture', Icons.museum, _selectedPlaceType == 'Culture'),
        const SizedBox(height: 12),
        _placeTypeCard('Détente', Icons.spa, _selectedPlaceType == 'Détente'),
        const SizedBox(height: 12),
        _placeTypeCard(
            'Aventure', Icons.hiking, _selectedPlaceType == 'Aventure'),
      ],
    );
  }

  Widget _buildShoppingCategorySelector() {
    return Column(
      children: [
        _placeTypeCard('Mode', Icons.checkroom, _selectedPlaceType == 'Mode'),
        const SizedBox(height: 12),
        _placeTypeCard('Électronique', Icons.devices,
            _selectedPlaceType == 'Électronique'),
        const SizedBox(height: 12),
        _placeTypeCard(
            'Alimentation', Icons.store, _selectedPlaceType == 'Alimentation'),
        const SizedBox(height: 12),
        _placeTypeCard('Maison', Icons.home, _selectedPlaceType == 'Maison'),
      ],
    );
  }

  Widget _buildEventTypeSelector() {
    return Column(
      children: [
        _placeTypeCard(
            'Anniversaire', Icons.cake, _selectedPlaceType == 'Anniversaire'),
        const SizedBox(height: 12),
        _placeTypeCard(
            'Mariage', Icons.favorite, _selectedPlaceType == 'Mariage'),
        const SizedBox(height: 12),
        _placeTypeCard(
            'Conférence', Icons.mic, _selectedPlaceType == 'Conférence'),
        const SizedBox(height: 12),
        _placeTypeCard('Fête', Icons.celebration, _selectedPlaceType == 'Fête'),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlacesSelectionScreen(
                activityType: widget.activityType,
                activityColor: widget.activityColor,
                activityData: {
                  'duration': _selectedDuration,
                  'destination': _destinationController.text,
                  'travelType': _selectedTravelType,
                  'budget': _budgetController.text,
                  'placeType': _selectedPlaceType,
                  'peopleCount': _selectedPeopleCount,
                  'equipment': _selectedEquipment.toList(),
                },
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.activityColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Continuer',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
