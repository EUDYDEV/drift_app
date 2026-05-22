import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/cart_model.dart';

class CustomTripPage extends StatefulWidget {
  const CustomTripPage({super.key});

  @override
  State<CustomTripPage> createState() => _CustomTripPageState();
}

class _CustomTripPageState extends State<CustomTripPage> {
  String _selectedCity = 'Assinie';
  String _selectedDuration = 'Week-end (2j)';
  double _budget = 250000;
  bool _isGenerating = false;
  bool _isGenerated = false;

  final List<String> _cities = [
    'Abidjan',
    'Assinie',
    'Yamoussoukro',
    'Grand-Bassam',
  ];
  final List<String> _durations = [
    '1 Jour',
    'Week-end (2j)',
    '1 Semaine',
    'Vacances (10j+)',
  ];

  void _generatePack() async {
    setState(() {
      _isGenerating = true;
      _isGenerated = false;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _isGenerated = true;
    });
  }

  // ── Calculs budget IA ────────────────────────────────────────────────────
  Map<String, int> get _budgetBreakdown {
    final total = _budget.round();
    Map<String, int> distribute(int amount, List<int> pcts) {
      var allocated = 0;
      final values = <String, int>{};
      final labels = ['Transport', 'Resto', 'Loisirs', 'Shopping'];
      for (var i = 0; i < labels.length; i++) {
        final v = (amount * pcts[i] / 100).round();
        values[labels[i]] = v;
        allocated += v;
      }
      values['Shopping'] = (values['Shopping'] ?? 0) + (amount - allocated);
      return values;
    }
    if (_selectedDuration.contains('Jour')) {
      return distribute(total, const [25, 35, 30, 10]);
    } else if (_selectedDuration.contains('Vacances')) {
      return distribute(total, const [20, 30, 35, 15]);
    } else {
      return distribute(total, const [30, 30, 25, 15]);
    }
  }

  bool get _restoBudgetIsTight =>
      _budgetBreakdown['Resto']! < _budget.round() * 0.15;

  String _formatFcfa(int value) {
    final raw = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    final prefix = value < 0 ? '- ' : '';
    return '$prefix${buffer.toString()} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        title: Text(
          'SUR MESURE',
          style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
              letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            _buildConfigurator(),
            if (_isGenerating) _buildLoadingState(),
            if (_isGenerated && !_isGenerating) _buildGeneratedPack(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurator() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.orange),
              const SizedBox(width: 8),
              Text('Vos Préférences',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText)),
            ],
          ),
          const SizedBox(height: 20),

          // Choix de la ville
          Text('Destination',
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grayText)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cities
                .map((city) => _buildChip(city, _selectedCity,
                    (v) => setState(() => _selectedCity = v)))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Choix de la durée
          Text('Durée du séjour',
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grayText)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durations
                .map((d) => _buildChip(d, _selectedDuration,
                    (v) => setState(() => _selectedDuration = v)))
                .toList(),
          ),

          const SizedBox(height: 30),

          // Choix du budget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget Global',
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grayText)),
              Text(
                '${_budget.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.orange.withValues(alpha:0.2),
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withValues(alpha:0.1),
              trackHeight: 6.0,
            ),
            child: Slider(
              value: _budget,
              min: 50000,
              max: 1500000,
              divisions: 145, // par palier de 10 000
              onChanged: (val) => setState(() => _budget = val),
            ),
          ),

          const SizedBox(height: 20),

          // Bouton Générer
          GestureDetector(
            onTap: _generatePack,
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.blueViolet,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gradientBlue.withValues(alpha:0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'GÉNÉRER LE PACK',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
      String label, String currentVal, ValueChanged<String> onSelect) {
    final isSelected = label == currentVal;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gradientBlue : AppColors.lightGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? AppColors.gradientBlue
                  : Colors.grey.withValues(alpha:0.2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.gradientPurple),
          const SizedBox(height: 16),
          Text(
            'Recherche des meilleures offres...',
            style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.grayText,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedPack() {
    return AnimatedOpacity(
      opacity: _isGenerated ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.2),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.black87),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pack Idéal : $_selectedCity',
                      style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _packItem(Icons.hotel, 'Hébergement',
                      'Hôtel Confort & Spa ($_selectedDuration)'),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white12)),
                  _packItem(Icons.directions_car, 'Chauffeur',
                      'Véhicule Premium à disposition'),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white12)),
                   _packItem(Icons.restaurant, 'Lieux inclus',
                       '2 Tables réservées & 1 Activité',
                       action: 'Modifier'),
                  const SizedBox(height: 24),
                  Text('Estimation',
                      style: GoogleFonts.montserrat(
                          fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    '${_budget.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                    style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFFD700)),
                  ),
                  const SizedBox(height: 14),
                  // ── Détail budget IA ──────────────────────────────────
                  _buildBudgetBreakdown(),
                  if (_restoBudgetIsTight)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha:0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_dining, color: AppColors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Budget resto serré : DriFt vous propose des adresses street-food autour de $_selectedCity.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      CartModel.add(CartItem(
                        id: 'custom_pack_${DateTime.now().millisecondsSinceEpoch}',
                        type: 'pack',
                        name: 'Pack Sur Mesure $_selectedCity',
                        subtitle: '$_selectedDuration · Tout Inclus',
                        priceDisplay: '${_budget.toInt()} FCFA',
                        priceValue: _budget.toInt(),
                        color: const Color(0xFFFFD700),
                        icon: Icons.auto_awesome,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Pack personnalisé ajouté !'),
                          backgroundColor: AppColors.green));
                      Navigator.pop(context); // Retour à l'accueil
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text('AJOUTER AU PANIER',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87))),
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

  Widget _packItem(IconData icon, String title, String desc, {String? action}) {
    return Row(
      children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white70, size: 20)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(desc,
              style:
                  GoogleFonts.montserrat(fontSize: 11, color: Colors.white54))
        ])),
        if (action != null)
          Text(action,
              style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gradientBlue,
                  decoration: TextDecoration.underline)),
      ],
    );
  }

  Widget _buildBudgetBreakdown() {
    final buckets = _budgetBreakdown;
    final labels = ['Transport', 'Resto', 'Loisirs', 'Shopping'];
    final colors = [
      const Color(0xFF70D6FF),
      const Color(0xFFFFC857),
      const Color(0xFF57CC99),
      const Color(0xFFF28482),
    ];
    final icons = [
      Icons.directions_car_outlined,
      Icons.restaurant_outlined,
      Icons.sports_esports_outlined,
      Icons.shopping_bag_outlined,
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                'Répartition suggérée',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(labels.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors[i].withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icons[i], color: colors[i], size: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    labels[i],
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatFcfa(buckets[labels[i]] ?? 0),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors[i],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
