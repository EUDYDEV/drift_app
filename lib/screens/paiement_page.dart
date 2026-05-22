import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/cart_model.dart';

class PaiementPage extends StatefulWidget {
  final List<CartItem> items;
  const PaiementPage({super.key, required this.items});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  int _selectedPayment = 0;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _confirmed = false;
  bool _isProcessing = false;

  static const List<_PaymentMethod> _methods = [
    _PaymentMethod('VISA', Icons.credit_card, 'Carte Visa', Color(0xFF1A1F71)),
    _PaymentMethod('MC', Icons.credit_card, 'MasterCard', Color(0xFFEB001B)),
    _PaymentMethod(
        'OM', Icons.phone_android, 'Orange Money', Color(0xFFFF7900)),
  ];

  int get _total => widget.items.fold(0, (s, i) => s + i.priceValue);

  String get _totalFormatted {
    final n = _total;
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildSummary(),
                  _buildPaymentSection(),
                  _buildPassengerSection(),
                  _buildTotalBlock(),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _confirmed
                  ? _buildSuccessButton()
                  : _buildConfirmButton(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'DÉTAILS DE PAIEMENT',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Récapitulatif ─────────────────────────────────────────────────────────
  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.items.map((item) => _summaryRow(item)),
        ],
      ),
    );
  }

  Widget _summaryRow(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: AppColors.grayText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.priceDisplay,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mode de paiement ──────────────────────────────────────────────────────
  Widget _buildPaymentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode de Paiement',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(
                _methods.length,
                (i) => _paymentOption(i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(int index) {
    final method = _methods[index];
    final isSelected = _selectedPayment == index;
    final isLast = index == _methods.length - 1;

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? method.color.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: index == 0 ? const Radius.circular(20) : Radius.zero,
            bottom: isLast ? const Radius.circular(20) : Radius.zero,
          ),
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 32,
              decoration: BoxDecoration(
                color: method.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: method.color, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  method.code,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: method.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                method.label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? method.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? method.color : AppColors.lightText,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Informations passager ─────────────────────────────────────────────────
  Widget _buildPassengerSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations Passager',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          _formField(
            controller: _nameCtrl,
            icon: Icons.person_outline,
            label: 'Nom complet',
            hint: 'Ex: Koné Jean-Baptiste',
          ),
          const SizedBox(height: 10),
          _formField(
            controller: _phoneCtrl,
            icon: Icons.phone_outlined,
            label: 'Numéro de téléphone',
            hint: '+225 07 00 00 00 00',
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _formField(
            controller: _emailCtrl,
            icon: Icons.email_outlined,
            label: 'Adresse e-mail',
            hint: 'exemple@email.com',
            keyboard: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(
            color: AppColors.grayText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle:
              GoogleFonts.montserrat(color: AppColors.lightText, fontSize: 13),
          prefixIcon: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ─── Total final ───────────────────────────────────────────────────────────
  Widget _buildTotalBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.blueViolet,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientBlue.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL À PAYER',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.items.length} prestation${widget.items.length > 1 ? 's' : ''}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Text(
              _totalFormatted,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bouton confirmer ──────────────────────────────────────────────────────
  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: _isProcessing
          ? null
          : () async {
              setState(() => _isProcessing = true);
              // Appel API attendu : POST /api/v1/payments
              // Délai différencié selon le mode de paiement
              final ms = _selectedPayment == 2 ? 500 : 700;
              await Future.delayed(Duration(milliseconds: ms));
              if (!mounted) return;
              CartModel.clear();
              setState(() {
                _isProcessing = false;
                _confirmed = true;
              });
            },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _isProcessing ? AppColors.grayText : AppColors.orange,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _isProcessing
                  ? AppColors.grayText.withOpacity(0.3)
                  : AppColors.orange.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Center(
          child: _isProcessing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Traitement en cours...',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Confirmer et Payer',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
          borderRadius: BorderRadius.circular(28),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Paiement Confirmé !',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethod {
  final String code;
  final IconData icon;
  final String label;
  final Color color;
  const _PaymentMethod(this.code, this.icon, this.label, this.color);
}
