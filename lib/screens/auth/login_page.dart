import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../main_navigation_page.dart';
import '../../models/user_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscure = true;
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
                    'Bienvenue',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connectez-vous pour continuer',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: AppColors.grayText),
                  ),
                  const SizedBox(height: 32),
                  _field(Icons.email_outlined, 'Email ou téléphone',
                      TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _passwordField(),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage()),
                      ),
                      child: Text(
                        'Mot de passe oublié ?',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gradientBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _loginButton(context),
                  const SizedBox(height: 22),
                  _divider(),
                  const SizedBox(height: 22),
                  _socialRow(),
                  const SizedBox(height: 28),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: AppColors.grayText),
                          children: [
                            const TextSpan(text: 'Pas encore de compte ? '),
                            TextSpan(
                              text: "S'inscrire",
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
      height: 220,
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
            if (Navigator.canPop(context))
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35), width: 2),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -0.08,
                  child: Text(
                    'D',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'DriFt',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: 'Mot de passe',
          hintStyle:
              GoogleFonts.montserrat(color: AppColors.lightText, fontSize: 14),
          prefixIcon: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppColors.blueViolet.createShader(b),
            child:
                const Icon(Icons.lock_outline, color: Colors.white, size: 20),
          ),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.lightText,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _loginButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final nav = Navigator.of(context);
        setState(() => _loading = true);
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() => _loading = false);
        UserSession.login(name: 'EUDY DANIEL', email: 'eudyproject@gmail.com');
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationPage()),
        );
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
                  'SE CONNECTER',
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

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou continuer avec',
            style: GoogleFonts.montserrat(
                fontSize: 11, color: AppColors.lightText),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
      ],
    );
  }

  Widget _socialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialBtn('G', const Color(0xFFEA4335)),
        const SizedBox(width: 16),
        _socialBtn('f', const Color(0xFF1877F2)),
        const SizedBox(width: 16),
        _socialBtn('☎', AppColors.orange),
      ],
    );
  }

  Widget _socialBtn(String label, Color color) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}
