import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/identity_document_service.dart';
import '../theme/app_colors.dart';

Future<bool> ensureSelfDriveVerification(BuildContext context) async {
  final authService = context.read<AuthService>();
  if (!authService.isAuthenticated) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Connectez-vous pour choisir une location sans chauffeur.'),
      ),
    );
    return false;
  }

  await authService.refreshProfile();
  if (authService.identityDocumentsVerified &&
      authService.drivingLicenseStatus == 'verified') {
    return true;
  }
  if (!context.mounted) return false;

  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _DrivingLicenseVerificationSheet(),
      ) ??
      false;
}

class _DrivingLicenseVerificationSheet extends StatefulWidget {
  const _DrivingLicenseVerificationSheet();

  @override
  State<_DrivingLicenseVerificationSheet> createState() =>
      _DrivingLicenseVerificationSheetState();
}

class _DrivingLicenseVerificationSheetState
    extends State<_DrivingLicenseVerificationSheet> {
  final ImagePicker _picker = ImagePicker();
  final IdentityDocumentService _documentService = IdentityDocumentService();

  bool _isUploading = false;
  String? _message;

  Future<void> _selectAndUpload() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2200,
    );
    if (file == null || !mounted) return;

    setState(() {
      _isUploading = true;
      _message = null;
    });

    final result = await _documentService.uploadDrivingLicense(
      file: file,
      authService: context.read<AuthService>(),
    );
    if (!mounted) return;

    setState(() {
      _isUploading = false;
      _message = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthService>().drivingLicenseStatus;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VERIFICATION SANS CHAUFFEUR',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status == 'pending'
                  ? 'Votre permis est en cours de verification. La location sans chauffeur sera active apres validation.'
                  : status == 'rejected'
                      ? 'Le document precedent a ete refuse. Transmettez une photo lisible de votre permis.'
                      : 'Une photo lisible du permis est obligatoire avant toute location sans chauffeur.',
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _selectAndUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.badge_outlined),
                label: Text(
                  _isUploading
                      ? 'Envoi securise...'
                      : 'Photographier ou choisir mon permis',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed:
                  _isUploading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Continuer avec chauffeur'),
            ),
          ],
        ),
      ),
    );
  }
}
