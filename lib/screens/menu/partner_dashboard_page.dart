import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class PartnerDashboardPage extends StatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        title: Text(
          'Dashboard Partenaires',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _hero(),
          const SizedBox(height: 20),
          _segmented(),
          const SizedBox(height: 18),
          _kpis(),
          const SizedBox(height: 20),
          _sectionTitle('Disponibilites et arrivees temps reel'),
          const SizedBox(height: 12),
          _availabilityBoard(),
          const SizedBox(height: 20),
          _sectionTitle('Validation des paiements'),
          const SizedBox(height: 12),
          _paymentsBoard(),
          const SizedBox(height: 20),
          _sectionTitle('Statistiques upsell'),
          const SizedBox(height: 12),
          _upsellBoard(),
        ],
      ),
    );
  }

  Widget _hero() {
    final isHotelier = _mode == 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isHotelier
            ? const LinearGradient(colors: [Color(0xFF10203A), Color(0xFF1D3B6F)])
            : const LinearGradient(colors: [Color(0xFF2E1900), Color(0xFF6A3C00)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHotelier ? 'Espace hotelier' : 'Espace restaurateur',
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isHotelier
                ? 'Pilotez les chambres, arrivees et paiements physiques ou numeriques.'
                : 'Gerez les reservations, l affluence du soir et l upsell contextuel.',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmented() {
    return Row(
      children: [
        Expanded(child: _modeButton(0, 'Hotelier')),
        const SizedBox(width: 10),
        Expanded(child: _modeButton(1, 'Restaurateur')),
      ],
    );
  }

  Widget _modeButton(int index, String label) {
    final active = _mode == index;
    return GestureDetector(
      onTap: () => setState(() => _mode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.darkText : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? AppColors.darkText : const Color(0xFFE1E5EE)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : AppColors.grayText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpis() {
    final items = _mode == 0
        ? const [
            _KpiData('Taux occ.', '78%', Icons.king_bed_outlined, AppColors.gradientBlue),
            _KpiData('Arrivees', '14', Icons.login_outlined, AppColors.green),
            _KpiData('Paiements', '7 en attente', Icons.payments_outlined, AppColors.orange),
            _KpiData('Upsell', '+22%', Icons.trending_up_outlined, Color(0xFF7E57C2)),
          ]
        : const [
            _KpiData('Tables', '31 / 40', Icons.table_restaurant_outlined, AppColors.gradientBlue),
            _KpiData('Services 19h', '12', Icons.schedule_outlined, AppColors.green),
            _KpiData('Reglements', '4 a valider', Icons.point_of_sale_outlined, AppColors.orange),
            _KpiData('Panier moyen', '+18%', Icons.bar_chart_outlined, Color(0xFF7E57C2)),
          ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return Container(
          width: 164,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: item.color),
              const SizedBox(height: 12),
              Text(
                item.label,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grayText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _availabilityBoard() {
    final rows = _mode == 0
        ? const [
            ['Suite lagune', '2 libres', 'Check-in 14:00'],
            ['Deluxe executive', '1 libre', 'Arrivee VIP 16:20'],
            ['Standard business', '5 libres', 'Demande late check-out'],
          ]
        : const [
            ['Table terrasse', '6 couverts', 'Pack diner 19:00'],
            ['Salon prive', '4 couverts', 'Anniversaire confirme'],
            ['Bar signature', '8 couverts', 'Demande upsell cocktails'],
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: rows.map((row) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row[0],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row[2],
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    row[1],
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _paymentsBoard() {
    final rows = _mode == 0
        ? const [
            ['Suite Senior · 250 000 FCFA', 'Reglement physique a l accueil'],
            ['Confort driver · 75 000 FCFA', 'Orange Money recu'],
          ]
        : const [
            ['Diner romantique · 52 000 FCFA', 'Paiement numerique en attente'],
            ['Table business · 24 000 FCFA', 'Reglement physique confirme'],
          ];

    return Column(
      children: rows.map((row) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row[0],
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row[1],
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  _paymentChip('Valider', AppColors.green),
                  const SizedBox(height: 8),
                  _paymentChip('Verifier', AppColors.orange),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _paymentChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _upsellBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upsell contextuel',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _bar('Spa / upgrade', 0.74),
          _bar('Late checkout', 0.52),
          _bar('Diner partenaire', 0.68),
        ],
      ),
    );
  }

  Widget _bar(String label, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppColors.darkText,
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData(this.label, this.value, this.icon, this.color);
}
