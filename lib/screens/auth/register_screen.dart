import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'widgets/drift_auth_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final identifier = _identifierController.text.trim();
    final isPhone = _isPhoneIdentifier(identifier);

    try {
      final success = await context.read<AuthService>().register(
            fullName: _nameController.text.trim(),
            email: identifier,
            phone: isPhone ? identifier : '',
            password: _passwordController.text,
          );
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        setState(() {
          _errorMessage =
              'Ce compte existe peut-être déjà. Vérifiez vos informations.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'L’inscription est momentanément indisponible. Réessayez dans un instant.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showSocialUnavailable(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'L’inscription avec $provider sera disponible prochainement.',
        ),
      ),
    );
  }

  bool _isPhoneIdentifier(String value) {
    final compact = value.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\+?\d{8,15}$').hasMatch(compact);
  }

  @override
  Widget build(BuildContext context) {
    return DriftAuthShell(
      mode: DriftAuthMode.register,
      title: 'Rejoignez Drift',
      subtitle:
          'Créez votre compte pour composer des expériences sur mesure en Côte d’Ivoire.',
      onLoginSelected: _openLogin,
      onRegisterSelected: () {},
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              _RegisterErrorMessage(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            DriftAuthField(
              controller: _nameController,
              label: 'Nom complet',
              hintText: 'Votre nom et prénom',
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Saisissez votre nom complet.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
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
                final identifier = value?.trim() ?? '';
                if (identifier.isEmpty) {
                  return 'Saisissez votre email ou votre numéro de téléphone.';
                }
                if (!identifier.contains('@') &&
                    !_isPhoneIdentifier(identifier)) {
                  return 'Saisissez un email ou un numéro valide.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DriftAuthField(
              controller: _passwordController,
              label: 'Mot de passe',
              hintText: '8 caractères minimum',
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.next,
              obscureText: _obscurePassword,
              enabled: !_isLoading,
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
                if (value == null || value.length < 8) {
                  return 'Utilisez au moins 8 caractères.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DriftAuthField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              hintText: 'Saisissez à nouveau votre mot de passe',
              prefixIcon: Icons.verified_user_outlined,
              textInputAction: TextInputAction.done,
              obscureText: _obscureConfirmation,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _register(),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmation
                    ? 'Afficher la confirmation'
                    : 'Masquer la confirmation',
                onPressed: _isLoading
                    ? null
                    : () => setState(
                          () => _obscureConfirmation = !_obscureConfirmation,
                        ),
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: driftAuthMuted,
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            DriftPrimaryButton(
              label: 'S’inscrire',
              isLoading: _isLoading,
              onPressed: _register,
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
                onPressed: _isLoading ? null : _openLogin,
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
                      const TextSpan(text: 'Vous avez déjà un compte ? '),
                      TextSpan(
                        text: 'Se connecter',
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

class _RegisterErrorMessage extends StatelessWidget {
  const _RegisterErrorMessage({required this.message});

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
