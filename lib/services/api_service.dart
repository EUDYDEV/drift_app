import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data,
      {String? token}) async {
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> get(String endpoint, {String? token}) async {
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data,
      {String? token}) async {
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> data, {
    AuthService? authService,
  }) async {
    final token = await (authService ?? AuthService()).getToken();
    return post(endpoint, data, token: token);
  }

  static Future<http.Response> authenticatedGet(
    String endpoint, {
    AuthService? authService,
  }) async {
    final token = await (authService ?? AuthService()).getToken();
    return get(endpoint, token: token);
  }

  static Future<http.Response> authenticatedPut(
    String endpoint,
    Map<String, dynamic> data, {
    AuthService? authService,
  }) async {
    final token = await (authService ?? AuthService()).getToken();
    return put(endpoint, data, token: token);
  }
}
