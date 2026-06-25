import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/drift_auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await context.read<AuthService>().login(
            email: _identifierController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;

      if (success) {
        final authService = context.read<AuthService>();
        Navigator.of(context).pushNamedAndRemoveUntil(
          authService.isDriver ? '/driver-mission' : '/home',
          (_) => false,
        );
      } else {
        setState(() {
          _errorMessage =
              'Identifiant ou mot de passe incorrect. Veuillez réessayer.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'La connexion est momentanément indisponible. Réessayez dans un instant.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _showSocialUnavailable(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'La connexion avec $provider sera disponible prochainement.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DriftAuthShell(
      mode: DriftAuthMode.login,
      title: 'Heureux de vous revoir',
      subtitle:
          'Accédez à vos trajets, expériences et réservations Drift en toute sécurité.',
      onLoginSelected: () {},
      onRegisterSelected: _openRegister,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              _AuthErrorMessage(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            DriftAuthField(
              controller: _identifierController,
              label: 'Identifiant',
              hintText: 'Email ou Numéro de téléphone',
              prefixIcon: adaptiveIdentifierIcon(_identifierController.text),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Saisissez votre email ou votre numéro de téléphone.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DriftAuthField(
              controller: _passwordController,
              label: 'Mot de passe',
              hintText: 'Votre mot de passe',
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              obscureText: _obscurePassword,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _login(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                onPressed: _isLoading
                    ? null
                    : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: driftAuthMuted,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Saisissez votre mot de passe.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                style: TextButton.styleFrom(
                  foregroundColor: driftAuthOrange,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'Mot de passe oublié ?',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            DriftPrimaryButton(
              label: 'Se connecter',
              isLoading: _isLoading,
              onPressed: _login,
            ),
            const SizedBox(height: 26),
            DriftSocialAuthBlock(
              onGoogle: () => _showSocialUnavailable('Google'),
              onFacebook: () => _showSocialUnavailable('Facebook'),
              onApple: () => _showSocialUnavailable('Apple'),
            ),
            const SizedBox(height: 28),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _openRegister,
                style: TextButton.styleFrom(
                  foregroundColor: driftAuthOrange,
                ),
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: driftAuthMuted,
                    ),
                    children: [
                      const TextSpan(text: 'Vous découvrez Drift ? '),
                      TextSpan(
                        text: 'Créer un compte',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                          color: driftAuthOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorMessage extends StatelessWidget {
  const _AuthErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD4B5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: driftAuthOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: driftAuthInk,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
