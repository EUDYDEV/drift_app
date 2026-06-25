import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Sur un appareil Android physique, l'émulateur n'est pas utilisé.
      // Utiliser l'IP locale de la machine hôte pour accéder au backend Docker.
      return 'http://192.168.200.19:8080';
    }
    return 'http://localhost:8080';
  }
}
