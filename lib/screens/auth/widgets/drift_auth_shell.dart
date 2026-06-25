import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color driftAuthOrange = Color(0xFFFF6A00);
const Color driftAuthBackground = Color(0xFFF5F5F7);
const Color driftAuthInk = Color(0xFF1A1A1C);
const Color driftAuthMuted = Color(0xFF747477);

enum DriftAuthMode { login, register }

class DriftAuthShell extends StatelessWidget {
  const DriftAuthShell({
    super.key,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.onLoginSelected,
    required this.onRegisterSelected,
    required this.child,
  });

  final DriftAuthMode mode;
  final String title;
  final String subtitle;
  final VoidCallback onLoginSelected;
  final VoidCallback onRegisterSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: driftAuthBackground,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = (constraints.maxHeight * 0.36).clamp(250.0, 330.0);
          final sheetTop = heroHeight - 32;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Stack(
                children: [
                  _AuthHero(height: heroHeight),
                  Padding(
                    padding: EdgeInsets.only(top: sheetTop),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - sheetTop,
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuthModeSwitcher(
                            mode: mode,
                            onLoginSelected: onLoginSelected,
                            onRegisterSelected: onRegisterSelected,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: driftAuthInk,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: driftAuthMuted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          child,
                        ],
                      ),
                    ),
                  ),
                  if (Navigator.canPop(context))
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 12,
                      left: 16,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Retour',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: driftAuthInk,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/auth_luxury_night.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.2, 0.42),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
          Center(
            child: Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeSwitcher extends StatelessWidget {
  const _AuthModeSwitcher({
    required this.mode,
    required this.onLoginSelected,
    required this.onRegisterSelected,
  });

  final DriftAuthMode mode;
  final VoidCallback onLoginSelected;
  final VoidCallback onRegisterSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: 'Connexion',
            selected: mode == DriftAuthMode.login,
            onTap: onLoginSelected,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _ModeButton(
            label: 'Inscription',
            selected: mode == DriftAuthMode.register,
            onTap: onRegisterSelected,
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? driftAuthInk : driftAuthMuted,
              ),
            ),
            const SizedBox(height: 9),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              color: selected ? driftAuthOrange : const Color(0xFFE1E1E4),
            ),
          ],
        ),
      ),
    );
  }
}

class DriftAuthField extends StatelessWidget {
  const DriftAuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: driftAuthInk,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 13,
          color: driftAuthMuted,
        ),
        hintStyle: GoogleFonts.montserrat(
          fontSize: 13,
          color: const Color(0xFFA5A5AA),
        ),
        prefixIcon: Icon(prefixIcon, color: driftAuthInk, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: driftAuthBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6E6E9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: driftAuthOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC9382B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC9382B), width: 1.5),
        ),
      ),
    );
  }
}

class DriftPrimaryButton extends StatelessWidget {
  const DriftPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: driftAuthOrange,
          disabledBackgroundColor: const Color(0xFFFFB37D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class DriftSocialAuthBlock extends StatelessWidget {
  const DriftSocialAuthBlock({
    super.key,
    required this.onGoogle,
    required this.onFacebook,
    required this.onApple,
  });

  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E2E5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ou continuer avec',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: driftAuthMuted,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E2E5))),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                semanticLabel: 'Continuer avec Google',
                onPressed: onGoogle,
                child: Text(
                  'G',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: driftAuthInk,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                semanticLabel: 'Continuer avec Facebook',
                onPressed: onFacebook,
                child: Text(
                  'f',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: driftAuthInk,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                semanticLabel: 'Continuer avec Apple',
                onPressed: onApple,
                child: const Icon(
                  Icons.apple,
                  size: 24,
                  color: driftAuthInk,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: driftAuthInk,
            side: const BorderSide(color: Color(0xFFDEDEE2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

IconData adaptiveIdentifierIcon(String value) {
  final trimmed = value.trim();
  if (trimmed.contains('@')) return Icons.email_outlined;
  if (RegExp(r'^[+\d\s-]+$').hasMatch(trimmed) && trimmed.isNotEmpty) {
    return Icons.phone_outlined;
  }
  return Icons.alternate_email;
}
