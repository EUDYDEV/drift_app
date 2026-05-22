import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/cart_model.dart';
import '../paiement_page.dart';
import 'chauffeur_detail_page.dart';
import 'chat_page.dart';

// ─── Données chauffeur simulé ─────────────────────────────────────────────
class _FakeDriver {
  final String name;
  final String sub;
  final double rating;
  final int trips;
  final String plate;
  final int etaMin;
  final Color color;
  const _FakeDriver({
    required this.name,
    required this.sub,
    required this.rating,
    required this.trips,
    required this.plate,
    required this.etaMin,
    required this.color,
  });
}

const _kDrivers = [
  _FakeDriver(
    name: 'Ibrahim Koné',
    sub: 'Chauffeur certifié · 5 ans',
    rating: 4.9,
    trips: 1247,
    plate: 'AB 1234 CI',
    etaMin: 8,
    color: Color(0xFF6C63FF),
  ),
  _FakeDriver(
    name: 'Kouassi Aimé',
    sub: 'Chauffeur VIP · 7 ans',
    rating: 4.8,
    trips: 2043,
    plate: 'CI 5678 AB',
    etaMin: 5,
    color: Color(0xFF1E90FF),
  ),
  _FakeDriver(
    name: 'Diarrassouba Mamadou',
    sub: 'Chauffeur Pro · 3 ans',
    rating: 4.7,
    trips: 689,
    plate: 'PL 9012 CI',
    etaMin: 12,
    color: Color(0xFF43A047),
  ),
];

const _kCities = [
  'Abidjan', 'Assinie', 'Grand-Bassam',
  'Yamoussoukro', 'Bouaké', 'San-Pédro',
];

const _kDates = ['Aujourd\'hui', 'Demain', 'Après-demain'];
const _kTimes = [
  '08:00', '09:00', '10:00', '11:00', '12:00',
  '14:00', '15:00', '16:00', '18:00', '20:00',
];

// ─── Page booking ─────────────────────────────────────────────────────────
class ChauffeurBookingPage extends StatefulWidget {
  final ChauffeurOption option;
  final int duration; // 0=12H 1=24H

  const ChauffeurBookingPage({
    super.key,
    required this.option,
    required this.duration,
  });

  @override
  State<ChauffeurBookingPage> createState() => _ChauffeurBookingPageState();
}

class _ChauffeurBookingPageState extends State<ChauffeurBookingPage>
    with TickerProviderStateMixin {
  // Étapes : 0=form  1=recherche  2=trouvé
  int _step = 0;

  // Form state
  int _cityIdx = 0;
  int _dateIdx = 0;
  int _timeIdx = 2;

  // Driver trouvé
  late _FakeDriver _driver;

  // Animation radar (étape 1)
  late AnimationController _radarCtrl;
  late Animation<double> _radarAnim;

  @override
  void initState() {
    super.initState();
    _driver = _kDrivers[Random().nextInt(_kDrivers.length)];
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _radarAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _radarCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    super.dispose();
  }

  void _startSearch() async {
    setState(() => _step = 1);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _step = 2);
  }

  String get _priceLabel =>
      widget.duration == 0 ? widget.option.price12h : widget.option.price24h;
  int get _priceValue => widget.duration == 0
      ? widget.option.priceValue12h
      : widget.option.priceValue24h;
  String get _durLabel => widget.duration == 0 ? '12H' : '24H';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _step == 1
          ? const Color(0xFF0A0A0F)
          : AppColors.lightGray,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _step == 0
            ? _buildForm()
            : _step == 1
                ? _buildSearching()
                : _buildFound(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ÉTAPE 0 — Formulaire
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Column(
      key: const ValueKey(0),
      children: [
        _formHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formSection('Ville de départ', _citySelector()),
                const SizedBox(height: 24),
                _formSection('Date', _dateSelector()),
                const SizedBox(height: 24),
                _formSection('Heure de prise en charge', _timeSelector()),
                const SizedBox(height: 24),
                _durationSummary(),
              ],
            ),
          ),
        ),
        _searchButton(),
      ],
    );
  }

  Widget _formHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 20,
        bottom: 16,
      ),
      color: AppColors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.lightGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.darkText, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réserver un chauffeur',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  widget.option.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: widget.option.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.option.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _durLabel,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: widget.option.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.grayText,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _citySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_kCities.length, (i) {
        final sel = _cityIdx == i;
        return GestureDetector(
          onTap: () => setState(() => _cityIdx = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? widget.option.accentColor : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel
                    ? widget.option.accentColor
                    : Colors.grey.withValues(alpha: 0.2),
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color:
                            widget.option.accentColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Text(
              _kCities[i],
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : AppColors.darkText,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _dateSelector() {
    return Row(
      children: List.generate(_kDates.length, (i) {
        final sel = _dateIdx == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _kDates.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _dateIdx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? widget.option.accentColor : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel
                        ? widget.option.accentColor
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _kDates[i],
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _timeSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _kTimes.length,
        itemBuilder: (_, i) {
          final sel = _timeIdx == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _timeIdx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: sel ? widget.option.accentColor : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? widget.option.accentColor
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    _kTimes[i],
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.darkText,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _durationSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: widget.option.accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.option.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.option.icon,
                color: widget.option.accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.option.name} · $_durLabel',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText)),
                Text(widget.option.tag,
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: AppColors.grayText)),
              ],
            ),
          ),
          Text(
            _priceLabel,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: widget.option.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchButton() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: GestureDetector(
        onTap: _startSearch,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              widget.option.accentColor,
              widget.option.accentColor.withValues(alpha: 0.8),
            ]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.option.accentColor.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'RECHERCHER UN CHAUFFEUR',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ÉTAPE 1 — Recherche animée
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSearching() {
    return Container(
      key: const ValueKey(1),
      color: const Color(0xFF0A0A0F),
      child: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _radarAnim,
              builder: (_, __) => CustomPaint(
                size: const Size(280, 280),
                painter: _RadarPainter(
                    _radarAnim.value, widget.option.accentColor),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.option.accentColor.withValues(alpha: 0.2),
                    border: Border.all(
                        color: widget.option.accentColor, width: 2),
                  ),
                  child: Icon(widget.option.icon,
                      color: widget.option.accentColor, size: 34),
                ),
                const SizedBox(height: 40),
                Text(
                  'Recherche en cours...',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Connexion aux chauffeurs à proximité',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: Colors.white38),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_kCities[_cityIdx]} · ${_kDates[_dateIdx]} · ${_kTimes[_timeIdx]}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: widget.option.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                _DotsIndicator(color: widget.option.accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ÉTAPE 2 — Chauffeur trouvé
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFound() {
    final d = _driver;
    return Column(
      key: const ValueKey(2),
      children: [
        _foundHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              children: [
                _driverCard(d),
                const SizedBox(height: 16),
                _actionButtons(d),
                const SizedBox(height: 20),
                _bookingSummary(),
              ],
            ),
          ),
        ),
        _payButton(d),
      ],
    );
  }

  Widget _foundHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 20,
        bottom: 16,
      ),
      color: AppColors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _step = 0),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.lightGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.darkText, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Chauffeur trouvé !',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${_driver.etaMin} min',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverCard(_FakeDriver d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [d.color, d.color.withValues(alpha: 0.6)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      d.sub,
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: AppColors.grayText),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${d.rating}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${d.trips} courses',
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: AppColors.grayText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(widget.option.icon,
                        color: widget.option.accentColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      widget.option.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkText.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    d.plate,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
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

  Widget _actionButtons(_FakeDriver d) {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            icon: Icons.phone_outlined,
            label: 'Appeler',
            color: AppColors.green,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Appel vers ${d.name}...',
                  style:
                      GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              backgroundColor: AppColors.green,
            )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(
            icon: Icons.chat_bubble_outline,
            label: 'Message',
            color: widget.option.accentColor,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatPage())),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.option.accentColor.withValues(alpha: 0.12),
            widget.option.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: widget.option.accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          _summaryRow(Icons.location_on_outlined, 'Ville',
              _kCities[_cityIdx]),
          _summaryRow(Icons.calendar_today_outlined, 'Date',
              _kDates[_dateIdx]),
          _summaryRow(
              Icons.access_time_outlined, 'Heure', _kTimes[_timeIdx]),
          _summaryRow(Icons.timer_outlined, 'Durée', _durLabel),
          const Divider(height: 20, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grayText,
                    letterSpacing: 1,
                  )),
              Text(
                _priceLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: widget.option.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: widget.option.accentColor),
          const SizedBox(width: 10),
          Text('$label :',
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: AppColors.grayText)),
          const SizedBox(width: 6),
          Text(value,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              )),
        ],
      ),
    );
  }

  Widget _payButton(_FakeDriver d) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: GestureDetector(
        onTap: () {
          final item = CartItem(
            id: 'chauffeur_${widget.option.id}_${DateTime.now().millisecondsSinceEpoch}',
            type: 'chauffeur',
            name: 'Chauffeur ${widget.option.name} · ${d.name}',
            subtitle:
                '${_kCities[_cityIdx]} · ${_kDates[_dateIdx]} · ${_kTimes[_timeIdx]} · $_durLabel',
            priceDisplay: _priceLabel,
            priceValue: _priceValue,
            color: widget.option.accentColor,
            icon: widget.option.icon,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaiementPage(items: [item]),
            ),
          );
        },
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'CONFIRMER ET PAYER · $_priceLabel',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Radar painter ────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RadarPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final p = ((progress - i * 0.33) % 1.0).clamp(0.0, 1.0);
      final radius = p * size.width / 2;
      final opacity = (1 - p) * 0.4;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Dots indicateur ─────────────────────────────────────────────────────
class _DotsIndicator extends StatefulWidget {
  final Color color;
  const _DotsIndicator({required this.color});

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final active = (_c.value * 3).floor() == i;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? widget.color
                  : widget.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
