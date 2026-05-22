import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final bool _obscure = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTop(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Créer un compte',
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rejoignez la communauté DriFt',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: AppColors.grayText),
                  ),
                  const SizedBox(height: 32),
                  _field(
                      Icons.person_outline, 'Nom complet', TextInputType.name),
                  const SizedBox(height: 14),
                  _field(Icons.email_outlined, 'Email',
                      TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _passwordField('Mot de passe'),
                  const SizedBox(height: 14),
                  _passwordField('Confirmer le mot de passe'),
                  const SizedBox(height: 28),
                  _registerButton(context),
                  const SizedBox(height: 28),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: AppColors.grayText),
                          children: [
                            const TextSpan(text: 'Déjà un compte ? '),
                            TextSpan(
                              text: "Se connecter",
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop(BuildContext context) {
    return Container(
      height: 160,
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
          ],
        ),
      ),
    );
  }

  Widget _field(IconData icon, String hint, TextInputType type) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.montserrat(color: AppColors.lightText, fontSize: 14),
          prefixIcon: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _passwordField(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.montserrat(color: AppColors.lightText, fontSize: 14),
          prefixIcon: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child:
                const Icon(Icons.lock_outline, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _registerButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        setState(() => _loading = true);
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() => _loading = false);
        navigator.pop();
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
                      color: Colors.white, strokeWidth: 2.5))
              : Text(
                  'S\'INSCRIRE',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }
}
