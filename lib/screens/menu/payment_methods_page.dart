import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethod {
  final String id;
  final String type; // 'card' | 'mobile'
  final String name;
  final String detail;
  final Color color;
  final String badge; // 'VISA', 'MC', 'OM', 'WAVE', 'MTN', 'MOOV'
  bool isDefault;

  _PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.detail,
    required this.color,
    required this.badge,
  }) : isDefault = false;
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final List<_PaymentMethod> _methods = [];

  static const _addOptions = [
    _AddOption('Carte bancaire', Icons.credit_card, Color(0xFF1A1F71)),
    _AddOption('Orange Money', Icons.phone_android, Color(0xFFFF7900)),
    _AddOption('Wave', Icons.waves, Color(0xFF1E3A5F)),
    _AddOption('MTN Mobile Money', Icons.phone_iphone, Color(0xFFFFCC02)),
    _AddOption('Moov Money', Icons.account_balance_wallet, Color(0xFF003DA5)),
  ];

  void _setDefault(String id) {
    setState(() {
      for (final m in _methods) {
        m.isDefault = m.id == id;
      }
    });
  }

  void _delete(String id) {
    setState(() => _methods.removeWhere((m) => m.id == id));
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMethodSheet(
        options: _addOptions,
        onSelect: (opt) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Ajout de ${opt.name} — fonctionnalité bientôt disponible',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.gradientBlue,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final cards = _methods.where((m) => m.type == 'card').toList();
    final mobile = _methods.where((m) => m.type == 'mobile').toList();

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.darkText, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Moyens de paiement',
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 72, color: AppColors.gradientBlue),
                const SizedBox(height: 24),
                Text(
                  'Veuillez vous connecter pour gérer vos moyens de paiement.',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: AppColors.darkText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueViolet.colors.first,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'SE CONNECTER',
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
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Moyens de paiement',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: AppColors.blueViolet,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: _showAddSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cards.isNotEmpty) ...[
              _sectionLabel('Cartes bancaires'),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: PageView.builder(
                  itemCount: cards.length,
                  controller: PageController(viewportFraction: 0.92),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _CreditCardWidget(
                      method: cards[i],
                      onSetDefault: () => _setDefault(cards[i].id),
                      onDelete: () => _confirmDelete(cards[i]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
            if (mobile.isNotEmpty) ...[
              _sectionLabel('Mobile Money'),
              const SizedBox(height: 12),
              ...mobile.map((m) => _MobileMethodTile(
                    method: m,
                    onSetDefault: () => _setDefault(m.id),
                    onDelete: () => _confirmDelete(m),
                  )),
              const SizedBox(height: 28),
            ],
            _buildAddButton(),
            if (_methods.isEmpty) _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.grayText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddSheet,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.gradientBlue.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppColors.blueViolet.createShader(b),
              child: const Icon(Icons.add_circle_outline,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppColors.blueViolet.createShader(b),
              child: Text(
                'Ajouter un moyen de paiement',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppColors.blueViolet.createShader(b),
              child: const Icon(Icons.payment_outlined,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun moyen de paiement',
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoutez une carte ou un compte Mobile Money',
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: AppColors.grayText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(_PaymentMethod method) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
        content: Text(
          'Supprimer ${method.name} (${method.detail}) ?',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.montserrat(color: AppColors.grayText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: GoogleFonts.montserrat(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) _delete(method.id);
  }
}

// ─── Widget carte bancaire ──────────────────────────────────────────────────
class _CreditCardWidget extends StatelessWidget {
  final _PaymentMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  const _CreditCardWidget(
      {required this.method,
      required this.onSetDefault,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [method.color, method.color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: method.color.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Puce
                    Container(
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Row(
                      children: [
                        if (method.isDefault)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Défaut',
                              style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        _cardMenuButton(context),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  method.detail,
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TITULAIRE',
                            style: GoogleFonts.montserrat(
                                color: Colors.white54,
                                fontSize: 8,
                                letterSpacing: 1)),
                        Text(
                            context.watch<AuthService>().userName.isNotEmpty
                                ? context.watch<AuthService>().userName
                                : '—',
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text(
                      method.badge,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'default',
          child: Row(children: [
            const Icon(Icons.check_circle_outline,
                size: 18, color: AppColors.gradientBlue),
            const SizedBox(width: 10),
            Text('Définir par défaut',
                style: GoogleFonts.montserrat(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            const SizedBox(width: 10),
            Text('Supprimer',
                style: GoogleFonts.montserrat(fontSize: 13, color: Colors.red)),
          ]),
        ),
      ],
      onSelected: (v) {
        if (v == 'default') onSetDefault();
        if (v == 'delete') onDelete();
      },
    );
  }
}

// ─── Tile Mobile Money ──────────────────────────────────────────────────────
class _MobileMethodTile extends StatelessWidget {
  final _PaymentMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  const _MobileMethodTile(
      {required this.method,
      required this.onSetDefault,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: method.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                method.badge,
                style: GoogleFonts.montserrat(
                  color: method.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gradientBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Défaut',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gradientBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  method.detail,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: AppColors.grayText),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'default',
                child: Row(children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.gradientBlue),
                  const SizedBox(width: 10),
                  Text('Définir par défaut',
                      style: GoogleFonts.montserrat(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 10),
                  Text('Supprimer',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.red)),
                ]),
              ),
            ],
            onSelected: (v) {
              if (v == 'default') onSetDefault();
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet ajouter ───────────────────────────────────────────────────
class _AddOption {
  final String name;
  final IconData icon;
  final Color color;
  const _AddOption(this.name, this.icon, this.color);
}

class _AddMethodSheet extends StatelessWidget {
  final List<_AddOption> options;
  final void Function(_AddOption) onSelect;
  const _AddMethodSheet({required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ajouter un moyen de paiement',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 20),
          ...options.map((opt) => _OptionTile(opt: opt, onSelect: onSelect)),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final _AddOption opt;
  final void Function(_AddOption) onSelect;
  const _OptionTile({required this.opt, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(opt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: opt.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(opt.icon, color: opt.color, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              opt.name,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.lightText),
          ],
        ),
      ),
    );
  }
}
