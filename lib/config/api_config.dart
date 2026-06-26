import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _productionBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.drift.ci',
  );

  static const String _localMobileBaseUrl = String.fromEnvironment(
    'LOCAL_API_BASE_URL',
    defaultValue: _productionBaseUrl,
  );

  static String get baseUrl {
    const configuredUrl = kIsWeb ? _productionBaseUrl : _localMobileBaseUrl;
    final uri = Uri.tryParse(configuredUrl.trim());

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        'API_BASE_URL doit contenir une URL absolue valide.',
      );
    }

    if (kIsWeb && uri.scheme != 'https' && !_isLocalDevelopmentHost(uri)) {
      throw StateError(
        'API_BASE_URL doit utiliser HTTPS pour une application Web publique.',
      );
    }

    return configuredUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  static bool _isLocalDevelopmentHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }
}
