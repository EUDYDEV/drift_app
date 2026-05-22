import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const List<_HistoryItem> _items = [
    _HistoryItem(
      icon: Icons.hotel,
      title: 'Hôtel Ivoire',
      subtitle: 'Chambre Deluxe · 2 nuits',
      date: '22 Avr 2026',
      price: '180 000 FCFA',
      status: _Status.completed,
    ),
    _HistoryItem(
      icon: Icons.directions_car,
      title: 'Chauffeur Privé',
      subtitle: 'Konan Sylvain · 24H Confort',
      date: '18 Avr 2026',
      price: '75 000 FCFA',
      status: _Status.completed,
    ),
    _HistoryItem(
      icon: Icons.hotel,
      title: 'La Palm Royal',
      subtitle: 'Suite Bungalow · 3 nuits',
      date: '10 Mar 2026',
      price: '450 000 FCFA',
      status: _Status.completed,
    ),
    _HistoryItem(
      icon: Icons.directions_car,
      title: 'Chauffeur Privé',
      subtitle: 'Trajet Aéroport · Standard',
      date: '02 Mar 2026',
      price: '45 000 FCFA',
      status: _Status.cancelled,
    ),
    _HistoryItem(
      icon: Icons.hotel,
      title: 'Sofitel Abidjan',
      subtitle: 'Chambre Supérieure · 1 nuit',
      date: '14 Jan 2026',
      price: '95 000 FCFA',
      status: _Status.completed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(context),
          _buildSummaryRow(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: _items.length,
              itemBuilder: (_, i) => _buildCard(_items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.blueViolet,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historique',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Vos réservations passées',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          _summaryChip('${_items.length} réservations', Icons.receipt_long,
              AppColors.gradientBlue),
          const SizedBox(width: 10),
          _summaryChip(
              '845 000 FCFA', Icons.payments_outlined, AppColors.orange),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_HistoryItem item) {
    final isCompleted = item.status == _Status.completed;
    final statusColor = isCompleted ? AppColors.green : Colors.red;
    final statusLabel = isCompleted ? 'Terminé' : 'Annulé';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: AppColors.blueViolet,
            ),
            child: Icon(item.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: AppColors.grayText),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.date,
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: AppColors.lightText),
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
                item.price,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Détails',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Status { completed, cancelled }

class _HistoryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String date;
  final String price;
  final _Status status;
  const _HistoryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.price,
    required this.status,
  });
}
