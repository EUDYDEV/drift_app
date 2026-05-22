import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final success = await context
          .read<AuthService>()
          .requestPasswordReset(_emailController.text);
      if (success && mounted) {
        setState(() => _emailSent = true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mot de passe oublié',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1a1a1a),
              ),
            ),
            const SizedBox(height: 16),
            if (!_emailSent) ...[
              Text(
                'Entrez votre email pour recevoir un lien de réinitialisation.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E90FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Envoyer le lien',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              Text(
                'Un lien de réinitialisation a été envoyé à votre adresse email.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.green),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
