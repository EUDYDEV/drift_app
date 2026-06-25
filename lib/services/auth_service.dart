import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService extends ChangeNotifier {
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'drift_auth_token';

  static String get _baseUrl => ApiConfig.baseUrl;

  String? _token;
  String _userName = '';
  String _userEmail = '';
  bool _isVip = false;
  bool _initialized = false;

  bool get isAuthenticated => _token != null;
  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get isVip => isAuthenticated && _isVip;

  static Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _token = await readToken();
    if (_token != null) {
      await _refreshProfile(clearTokenOnUnauthorized: true);
    }

    notifyListeners();
  }

  Future<String?> getToken() async {
    _token ??= await readToken();
    return _token;
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final _ = phone;
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 201) {
        debugPrint('Echec inscription: ${response.statusCode} ${response.body}');
        return false;
      }

      final data = _decodeJson(response.body);
      await _persistSession(
        token: data['token'] as String?,
        userJson: data['user'] as Map<String, dynamic>?,
        fallbackName: fullName,
        fallbackEmail: email,
      );
      return true;
    } catch (e) {
      debugPrint('Erreur reseau inscription: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        debugPrint('Echec connexion: ${response.statusCode} ${response.body}');
        return false;
      }

      final data = _decodeJson(response.body);
      await _persistSession(
        token: data['token'] as String?,
        userJson: data['user'] as Map<String, dynamic>?,
        fallbackName: 'Utilisateur',
        fallbackEmail: email,
      );
      return true;
    } catch (e) {
      debugPrint('Erreur reseau connexion: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    await _refreshProfile(clearTokenOnUnauthorized: true);
    if (_token == null) return null;

    return {
      'email': _userEmail,
      'fullName': _userName,
      'isVip': _isVip,
    };
  }

  Future<void> logout() async {
    await _clearSession();
  }

  Future<bool> requestPasswordReset(String email) async {
    final url = Uri.parse('$_baseUrl/auth/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        return true;
      }

      debugPrint(
        'Reset password failed: ${response.statusCode} ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('Erreur reset password: $e');
      return false;
    }
  }

  Future<void> _persistSession({
    required String? token,
    required Map<String, dynamic>? userJson,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    if (token == null || token.isEmpty) {
      throw StateError('Backend auth response is missing token');
    }

    _token = token;
    await _storage.write(key: _tokenKey, value: token);
    _applyUser(
      userJson,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
    notifyListeners();
  }

  Future<bool> _refreshProfile({
    required bool clearTokenOnUnauthorized,
  }) async {
    final token = _token ?? await readToken();
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/auth/me');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = _decodeJson(response.body);
        _token = token;
        _applyUser(data);
        return true;
      }

      if (clearTokenOnUnauthorized &&
          (response.statusCode == 401 || response.statusCode == 403)) {
        await _clearSession(notify: false);
      }

      debugPrint(
        'Profile fetch failed: ${response.statusCode} ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('Erreur recuperation profil: $e');
      return false;
    }
  }

  void _applyUser(
    Map<String, dynamic>? userJson, {
    String fallbackName = '',
    String fallbackEmail = '',
  }) {
    final data = userJson ?? const <String, dynamic>{};
    _userName = _stringValue(data, 'fullName', 'full_name') ?? fallbackName;
    _userEmail = _stringValue(data, 'email') ?? fallbackEmail;
    _isVip = _boolValue(data, 'isVip', 'is_vip');
  }

  Future<void> _clearSession({bool notify = true}) async {
    _token = null;
    _userName = '';
    _userEmail = '';
    _isVip = false;
    await _storage.delete(key: _tokenKey);
    if (notify) {
      notifyListeners();
    }
  }

  Map<String, dynamic> _decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Expected JSON object');
  }

  String? _stringValue(
    Map<String, dynamic> data,
    String key, [
    String? alternateKey,
  ]) {
    final dynamic direct = data[key];
    if (direct is String && direct.isNotEmpty) return direct;

    if (alternateKey != null) {
      final dynamic alternate = data[alternateKey];
      if (alternate is String && alternate.isNotEmpty) return alternate;
    }

    return null;
  }

  bool _boolValue(
    Map<String, dynamic> data,
    String key, [
    String? alternateKey,
  ]) {
    final direct = data[key];
    if (direct is bool) return direct;
    if (alternateKey != null && data[alternateKey] is bool) {
      return data[alternateKey] as bool;
    }
    return false;
  }
}
