import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chauffeur_booking_page.dart';

// ─── Modèles de données ─────────────────────────────────────────────────────

class FeatureItem {
  final IconData icon;
  final String label;
  const FeatureItem(this.icon, this.label);
}

class ChauffeurOption {
  final String id;
  final String name;
  final String tag;
  final String description;
  final String price12h;
  final String price24h;
  final int priceValue12h;
  final int priceValue24h;
  final IconData icon;
  final Color accentColor;
  final String exteriorUrl;
  final List<String> interiorUrls;
  final List<FeatureItem> features;
  final List<String> chips;

  const ChauffeurOption({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.price12h,
    required this.price24h,
    required this.priceValue12h,
    required this.priceValue24h,
    required this.icon,
    required this.accentColor,
    required this.exteriorUrl,
    required this.interiorUrls,
    required this.features,
    required this.chips,
  });
}

class ChauffeurPlan {
  final String name;
  final String price;
  final int priceValue;
  final String subtitle;
  final List<String> perks;
  final Color gradientStart;
  final Color gradientEnd;
  final bool isPopular;

  const ChauffeurPlan({
    required this.name,
    required this.price,
    required this.priceValue,
    required this.subtitle,
    required this.perks,
    required this.gradientStart,
    required this.gradientEnd,
    this.isPopular = false,
  });
}

// ─── Données véhicules ───────────────────────────────────────────────────────

const kChauffeurOptions = [
  ChauffeurOption(
    id: 'sans_auto',
    name: 'SANS AUTO',
    tag: 'CHAUFFEUR SEUL',
    description:
        'Votre chauffeur professionnel conduit votre propre véhicule. Idéal si vous souhaitez rester discret ou si vous avez un véhicule de fonction.',
    price12h: '20 000 FCFA',
    price24h: '35 000 FCFA',
    priceValue12h: 20000,
    priceValue24h: 35000,
    icon: Icons.person_pin,
    accentColor: Color(0xFF607D8B),
    exteriorUrl:
        'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=800&q=80',
    interiorUrls: [
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80',
      'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800&q=80',
    ],
    chips: ['Votre véhicule', 'Professionnel', 'Discret'],
    features: [
      FeatureItem(Icons.verified, 'Chauffeur certifié & vérifié'),
      FeatureItem(Icons.language, 'Français · Anglais · Dioula'),
      FeatureItem(Icons.phone_android, 'Joignable à tout moment'),
      FeatureItem(Icons.shield, 'Assurance passagers incluse'),
      FeatureItem(Icons.child_care, 'Compatible siège enfant'),
      FeatureItem(Icons.pets, 'Animaux acceptés'),
    ],
  ),
  ChauffeurOption(
    id: 'standard',
    name: 'STANDARD',
    tag: 'BERLINE 4 PLACES',
    description:
        'Toyota Corolla ou équivalent. Confortable et fiable, idéal pour vos déplacements professionnels ou personnels dans Abidjan et sa région.',
    price12h: '45 000 FCFA',
    price24h: '75 000 FCFA',
    priceValue12h: 45000,
    priceValue24h: 75000,
    icon: Icons.directions_car_outlined,
    accentColor: Color(0xFF1E90FF),
    exteriorUrl:
        'https://images.unsplash.com/photo-1546614042-7df3c24c9e5d?w=800&q=80',
    interiorUrls: [
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80',
      'https://images.unsplash.com/photo-1585503418537-88331351ad99?w=800&q=80',
      'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800&q=80',
    ],
    chips: ['4 Places', 'Climatisation', 'WiFi'],
    features: [
      FeatureItem(Icons.airline_seat_recline_normal, '4 places passagers'),
      FeatureItem(Icons.ac_unit, 'Climatisation puissante'),
      FeatureItem(Icons.wifi, 'WiFi 4G à bord'),
      FeatureItem(Icons.usb, 'Chargeurs USB × 2'),
      FeatureItem(Icons.volume_off, 'Conduite silencieuse'),
      FeatureItem(Icons.local_drink, 'Eau fraîche disponible'),
    ],
  ),
  ChauffeurOption(
    id: 'confort',
    name: 'CONFORT',
    tag: 'BERLINE PREMIUM 5 PLACES',
    description:
        'Mercedes C-Class ou Toyota Camry. Finitions soignées, espace généreux et équipements premium pour une expérience au-dessus du standard.',
    price12h: '75 000 FCFA',
    price24h: '130 000 FCFA',
    priceValue12h: 75000,
    priceValue24h: 130000,
    icon: Icons.directions_car,
    accentColor: Color(0xFF6C63FF),
    exteriorUrl:
        'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&q=80',
    interiorUrls: [
      'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800&q=80',
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80',
      'https://images.unsplash.com/photo-1585503418537-88331351ad99?w=800&q=80',
    ],
    chips: ['5 Places', 'Cuir', 'WiFi', 'Eau'],
    features: [
      FeatureItem(Icons.airline_seat_legroom_extra, '5 places cuir premium'),
      FeatureItem(Icons.ac_unit, 'Climatisation bi-zone'),
      FeatureItem(Icons.wifi, 'WiFi 4G haut débit'),
      FeatureItem(Icons.local_drink, 'Eau minérale & rafraîchissements'),
      FeatureItem(Icons.power, 'Prise 220V & USB-C'),
      FeatureItem(Icons.privacy_tip, 'Vitres teintées'),
      FeatureItem(Icons.music_note, 'Sono premium (choix musique)'),
    ],
  ),
  ChauffeurOption(
    id: 'luxe',
    name: 'LUXE',
    tag: 'SUV / VAN VIP · 7 PLACES',
    description:
        'Range Rover, Mercedes V-Class ou BMW X7. L\'excellence absolue pour vos déplacements VIP, délégations officielles, ou occasions exceptionnelles.',
    price12h: '150 000 FCFA',
    price24h: '250 000 FCFA',
    priceValue12h: 150000,
    priceValue24h: 250000,
    icon: Icons.airport_shuttle,
    accentColor: Color(0xFFFFD700),
    exteriorUrl:
        'https://images.unsplash.com/photo-1563720223185-11003d516935?w=800&q=80',
    interiorUrls: [
      'https://images.unsplash.com/photo-1540324155974-7523202daa3f?w=800&q=80',
      'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800&q=80',
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80',
    ],
    chips: ['7 Places', 'Cuir', 'Mini-bar', 'WiFi'],
    features: [
      FeatureItem(Icons.airline_seat_flat, '7 places cuir nappa'),
      FeatureItem(Icons.wine_bar, 'Mini-bar privé à bord'),
      FeatureItem(Icons.wifi, 'WiFi 5G · Borne de charge'),
      FeatureItem(Icons.speaker, 'Sono Bose / Burmester'),
      FeatureItem(Icons.privacy_tip, 'Partition vitré chauffeur'),
      FeatureItem(Icons.workspace_premium, 'Protocole VIP & accueil'),
      FeatureItem(Icons.local_airport, 'Tarmac & protocole aéroport'),
    ],
  ),
];

// ─── Abonnements ─────────────────────────────────────────────────────────────

const kChauffeurPlans = [
  ChauffeurPlan(
    name: 'Starter',
    price: '45 000',
    priceValue: 45000,
    subtitle: '4 courses / mois',
    gradientStart: Color(0xFF4FC3F7),
    gradientEnd: Color(0xFF0288D1),
    perks: [
      '4 courses Standard incluses',
      'Réservation 1h à l\'avance',
      '-10% sur les courses supp.',
      'Support standard',
    ],
  ),
  ChauffeurPlan(
    name: 'Business',
    price: '120 000',
    priceValue: 120000,
    subtitle: '10 courses / mois',
    gradientStart: Color(0xFF6C63FF),
    gradientEnd: Color(0xFF3D5AFE),
    isPopular: true,
    perks: [
      '10 courses Confort incluses',
      'Réservation 30 min à l\'avance',
      '-20% sur toutes les courses',
      'Chauffeur dédié assigné',
      'Facturation mensuelle TVA',
    ],
  ),
  ChauffeurPlan(
    name: 'VIP',
    price: '350 000',
    priceValue: 350000,
    subtitle: 'Illimité · 24h/7j',
    gradientStart: Color(0xFFFFD700),
    gradientEnd: Color(0xFFFFA500),
    perks: [
      'Courses Luxe illimitées',
      'Chauffeur attitré (même chauf.)',
      'Disponible 24h/24 · 7j/7',
      'Conciergerie DriFt incluse',
      'Transferts aéroport inclus',
    ],
  ),
];

// ─── Page détail véhicule ────────────────────────────────────────────────────

class ChauffeurDetailPage extends StatefulWidget {
  final ChauffeurOption option;
  final int initialDuration; // 0 = 12H, 1 = 24H

  const ChauffeurDetailPage({
    super.key,
    required this.option,
    this.initialDuration = 0,
  });

  @override
  State<ChauffeurDetailPage> createState() => _ChauffeurDetailPageState();
}

class _ChauffeurDetailPageState extends State<ChauffeurDetailPage> {
  late int _duration; // 0 = 12H, 1 = 24H

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
  }

  String get _currentPrice =>
      _duration == 0 ? widget.option.price12h : widget.option.price24h;

  @override
  Widget build(BuildContext context) {
    final opt = widget.option;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(opt),
                _buildInfoSection(opt),
                _buildInteriorSection(opt),
                _buildFeaturesSection(opt),
                _buildPricingSection(opt),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildReserveButton(context, opt),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(ChauffeurOption opt) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            opt.exteriorUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: opt.accentColor.withValues(alpha: 0.3),
              child: Icon(opt.icon, size: 80, color: opt.accentColor),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0F0F0F).withValues(alpha: 0.8),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // Tag + name
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: opt.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    opt.tag,
                    style: GoogleFonts.montserrat(
                      color: opt.accentColor == const Color(0xFFFFD700)
                          ? Colors.black87
                          : Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  opt.name,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ChauffeurOption opt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            opt.description,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.white60,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: opt.chips.map((c) => _chip(c, opt.accentColor)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color == const Color(0xFFFFD700) ? color : Colors.white,
        ),
      ),
    );
  }

  Widget _buildInteriorSection(ChauffeurOption opt) {
    if (opt.interiorUrls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: opt.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Intérieur du véhicule',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: opt.interiorUrls.length,
              itemBuilder: (_, i) => Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white10,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  opt.interiorUrls[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: opt.accentColor.withValues(alpha: 0.2),
                    child: Icon(Icons.image_outlined,
                        color: opt.accentColor, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(ChauffeurOption opt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: opt.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ce qui est inclus',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...opt.features.map((f) => _featureTile(f, opt.accentColor)),
        ],
      ),
    );
  }

  Widget _featureTile(FeatureItem f, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(f.icon, color: accent, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            f.label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ChauffeurOption opt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: opt.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tarifs',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _priceTile('12 HEURES', opt.price12h, 0, opt.accentColor)),
              const SizedBox(width: 12),
              Expanded(child: _priceTile('24 HEURES', opt.price24h, 1, opt.accentColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceTile(String label, String price, int val, Color accent) {
    final isSelected = _duration == val;
    return GestureDetector(
      onTap: () => setState(() => _duration = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isSelected ? accent : Colors.white38,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReserveButton(BuildContext context, ChauffeurOption opt) {
    final durLabel = _duration == 0 ? '12H' : '24H';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChauffeurBookingPage(
              option: opt,
              duration: _duration,
            ),
          ),
        );
      },
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [opt.accentColor, opt.accentColor.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: opt.accentColor.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'RÉSERVER · $_currentPrice ($durLabel)',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: opt.accentColor == const Color(0xFFFFD700)
                  ? Colors.black87
                  : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
