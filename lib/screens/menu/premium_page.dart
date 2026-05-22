import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/chauffeur_detail_page.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  int _selectedPlan = 1; // Business sélectionné par défaut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context),
            _buildSectionLabel('Choisissez votre plan'),
            const SizedBox(height: 4),
            _buildPlanCards(),
            const SizedBox(height: 28),
            _buildSelectedPlanPerks(),
            const SizedBox(height: 28),
            _buildSubscribeButton(context),
            const SizedBox(height: 16),
            _buildCompareLink(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 56,
        bottom: 36,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kChauffeurPlans[_selectedPlan].gradientStart.withValues(alpha: 0.25),
            const Color(0xFF0F0F0F),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                kChauffeurPlans[_selectedPlan].gradientStart,
                kChauffeurPlans[_selectedPlan].gradientEnd,
              ]),
              boxShadow: [
                BoxShadow(
                  color: kChauffeurPlans[_selectedPlan]
                      .gradientStart
                      .withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'DriFt Pass',
            style: GoogleFonts.montserrat(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chauffeur à volonté. Expérience sans compromis.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Label section ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ─── Cards des 3 plans ────────────────────────────────────────────────────
  Widget _buildPlanCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: List.generate(
          kChauffeurPlans.length,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: i < kChauffeurPlans.length - 1 ? 10 : 0),
              child: _planCard(i),
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard(int index) {
    final plan = kChauffeurPlans[index];
    final isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [plan.gradientStart, plan.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? null
              : Border.all(color: Colors.white12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: plan.gradientStart.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (plan.isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'POPULAIRE',
                  style: GoogleFonts.montserrat(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Text(
              plan.name,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.price,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'FCFA/mois',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                color: isSelected
                    ? Colors.white70
                    : Colors.white38,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plan.subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                color: isSelected ? Colors.white70 : Colors.white30,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Avantages du plan sélectionné ───────────────────────────────────────
  Widget _buildSelectedPlanPerks() {
    final plan = kChauffeurPlans[_selectedPlan];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedPlan),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [plan.gradientStart, plan.gradientEnd],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Inclus dans ${plan.name}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...plan.perks.map((p) => _perkRow(p, plan.gradientStart)),
          ],
        ),
      ),
    );
  }

  Widget _perkRow(String perk, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: color, size: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              perk,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bouton souscrire ─────────────────────────────────────────────────────
  Widget _buildSubscribeButton(BuildContext context) {
    final plan = kChauffeurPlans[_selectedPlan];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Abonnement ${plan.name} — bientôt disponible !',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            backgroundColor: plan.gradientStart,
          ));
        },
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [plan.gradientStart, plan.gradientEnd]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: plan.gradientStart.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'S\'ABONNER · ${plan.price} FCFA / MOIS',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: plan.gradientStart == const Color(0xFFFFD700)
                    ? Colors.black87
                    : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompareLink(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCompareSheet(context),
      child: Text(
        'Comparer tous les plans →',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: Colors.white38,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white38,
        ),
      ),
    );
  }

  void _showCompareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Comparaison des plans',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                _tableHeader(),
                _tableRow('Courses incluses', '4 Std', '10 Cft', '∞ Luxe'),
                _tableRow('Réservation', '1h', '30 min', 'Immédiate'),
                _tableRow('Remise supp.', '-10%', '-20%', '-100%'),
                _tableRow('Chauffeur dédié', '—', '✓', '✓'),
                _tableRow('Aéroport', '—', '—', '✓'),
                _tableRow('Conciergerie', '—', '—', '✓'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _tableHeader() {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      children: [
        const SizedBox(height: 32),
        ...kChauffeurPlans.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                p.name,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: p.gradientStart,
                ),
                textAlign: TextAlign.center,
              ),
            )),
      ],
    );
  }

  TableRow _tableRow(String label, String v1, String v2, String v3) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
                fontSize: 11, color: Colors.white54),
          ),
        ),
        ...([v1, v2, v3].map((v) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  v,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: v == '—' ? Colors.white24 : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ))),
      ],
    );
  }
}
