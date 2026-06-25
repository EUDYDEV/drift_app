import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

class IdentityDocumentUploadResult {
  final bool accepted;
  final String message;

  const IdentityDocumentUploadResult({
    required this.accepted,
    required this.message,
  });
}

class IdentityDocumentService {
  Future<IdentityDocumentUploadResult> uploadDrivingLicense({
    required XFile file,
    required AuthService authService,
  }) async {
    final token = await authService.getToken();
    if (token == null) {
      return const IdentityDocumentUploadResult(
        accepted: false,
        message: 'Connectez-vous avant de transmettre votre permis.',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
      return const IdentityDocumentUploadResult(
        accepted: false,
        message: 'Le fichier doit peser moins de 8 Mo.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConfig.baseUrl}/auth/documents/driving-license',
      ),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
          contentType: _mediaType(file.mimeType),
        ),
      );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 202) {
        await authService.refreshProfile();
        return const IdentityDocumentUploadResult(
          accepted: true,
          message:
              'Permis transmis. La verification Drift est maintenant en attente.',
        );
      }

      return IdentityDocumentUploadResult(
        accepted: false,
        message: _extractError(response.body) ??
            'Le permis n’a pas pu etre transmis.',
      );
    } catch (error) {
      return IdentityDocumentUploadResult(
        accepted: false,
        message: 'Erreur lors de l’envoi du permis : $error',
      );
    }
  }

  MediaType _mediaType(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || !value.contains('/')) {
      return MediaType('image', 'jpeg');
    }
    final parts = value.split('/');
    return MediaType(parts.first, parts.last);
  }

  String? _extractError(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
