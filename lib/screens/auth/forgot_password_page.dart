import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool _loading = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildTop(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: _sent ? _buildConfirmation() : _buildForm(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.blueViolet,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35), width: 2),
              ),
              child: const Icon(Icons.lock_reset, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Mot de passe oublié',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réinitialiser',
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Entrez votre email pour recevoir un lien de réinitialisation',
          style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.grayText),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(18),
          ),
          child: TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Email',
              hintStyle: GoogleFonts.montserrat(
                  color: AppColors.lightText, fontSize: 14),
              prefixIcon: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => AppColors.blueViolet.createShader(b),
                child: const Icon(Icons.email_outlined,
                    color: Colors.white, size: 20),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () async {
            setState(() => _loading = true);
            await Future.delayed(const Duration(milliseconds: 900));
            if (!mounted) return;
            setState(() {
              _loading = false;
              _sent = true;
            });
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.blueViolet,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientBlue.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'ENVOYER LE LIEN',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.gradientBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              size: 40, color: AppColors.gradientBlue),
        ),
        const SizedBox(height: 24),
        Text(
          'Email envoyé !',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Vérifiez votre boîte mail et suivez les instructions pour réinitialiser votre mot de passe.',
          style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.grayText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.blueViolet,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientBlue.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'RETOUR À LA CONNEXION',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
