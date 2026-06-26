import 'dart:convert';

import '../models/admin_dashboard_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AdminService {
  AdminService({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<bool> masterCreatorLogin(String masterCreatorKey) {
    return _authService.masterCreatorLogin(masterCreatorKey: masterCreatorKey);
  }

  Future<AdminDashboardLayout> fetchLayout() async {
    final response = await ApiService.authenticatedGet(
      '/api/admin/layout',
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return AdminDashboardLayout.fromJson(_decodeObject(response.body));
  }

  Future<AdminSummary> fetchSummary() async {
    final response = await ApiService.authenticatedGet(
      '/api/admin/summary',
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return AdminSummary.fromJson(_decodeObject(response.body));
  }

  Future<List<AdminFeatureFlag>> fetchFeatureFlags() async {
    final response = await ApiService.authenticatedGet(
      '/api/admin/feature-flags',
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeList(response.body)
        .map((item) => AdminFeatureFlag.fromJson(_asObject(item)))
        .toList(growable: false);
  }

  Future<AdminFeatureFlag> updateFeatureFlag({
    required String flagKey,
    required bool enabled,
    required int rolloutPercentage,
    Map<String, dynamic>? audience,
  }) async {
    final response = await ApiService.authenticatedPut(
      '/api/admin/feature-flags/$flagKey',
      {
        'enabled': enabled,
        'rolloutPercentage': rolloutPercentage,
        'audience': audience ?? const <String, dynamic>{},
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return AdminFeatureFlag.fromJson(_decodeObject(response.body));
  }

  Future<List<AdminMaintenanceMode>> fetchMaintenanceModes() async {
    final response = await ApiService.authenticatedGet(
      '/api/admin/maintenance',
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeList(response.body)
        .map((item) => AdminMaintenanceMode.fromJson(_asObject(item)))
        .toList(growable: false);
  }

  Future<AdminMaintenanceMode> upsertMaintenanceMode({
    required String scopeType,
    String? scopeValue,
    required bool enabled,
    required String message,
  }) async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/maintenance',
      {
        'scopeType': scopeType,
        'scopeValue': scopeValue,
        'enabled': enabled,
        'message': message,
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return AdminMaintenanceMode.fromJson(_decodeObject(response.body));
  }

  Future<AdminFinanceOverview> fetchFinanceOverview() async {
    final response = await ApiService.authenticatedGet(
      '/api/admin/finance/overview',
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return AdminFinanceOverview.fromJson(_decodeObject(response.body));
  }

  Future<Map<String, dynamic>> triggerGithubDeploy({
    String? workflow,
    String? branch,
    String? environment,
  }) async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/github/deploy',
      {
        'workflow': workflow,
        'branch': branch,
        'environment': environment,
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<Map<String, dynamic>> runPentest() async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/security/pentest',
      const <String, dynamic>{},
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<Map<String, dynamic>> fetchEncryptionHealth() async {
    final response = await ApiService.authenticatedGet(
      '/api/admin/security/encryption-health',
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<Map<String, dynamic>> killSwitchUser({
    required String userId,
    required String reason,
    String? partnerId,
  }) async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/users/$userId/kill-switch',
      {
        'reason': reason,
        'partnerId': partnerId,
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<Map<String, dynamic>> updateUserPermissions({
    required String userId,
    required String roleKey,
    required List<String> permissions,
  }) async {
    final response = await ApiService.authenticatedPut(
      '/api/admin/roles/$userId/permissions',
      {
        'roleKey': roleKey,
        'permissions': permissions,
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<Map<String, dynamic>> reviewPartnerOnboarding({
    required String partnerId,
    required bool approved,
    String? reason,
  }) async {
    final response = await ApiService.authenticatedPut(
      '/api/admin/partners/$partnerId/onboarding',
      {
        'approved': approved,
        'reason': reason,
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<Map<String, dynamic>> anonymizeUser(String userId) async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/privacy/anonymize/$userId',
      const <String, dynamic>{},
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<List<Map<String, dynamic>>> fetchSecurityEvents() {
    return _fetchObjectList('/api/admin/security/events');
  }

  Future<List<Map<String, dynamic>>> fetchItExpenses() {
    return _fetchObjectList('/api/admin/it-expenses');
  }

  Future<Map<String, dynamic>> createItExpense({
    required String provider,
    required String category,
    required double amount,
    String currency = 'XOF',
    String billingPeriod = '',
    String notes = '',
  }) async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/it-expenses',
      {
        'provider': provider,
        'category': category,
        'amount': amount,
        'currency': currency,
        'billingPeriod': billingPeriod,
        'notes': notes,
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<List<Map<String, dynamic>>> fetchReviews() {
    return _fetchObjectList('/api/admin/reviews');
  }

  Future<Map<String, dynamic>> moderateReview({
    required String reviewId,
    required String status,
    String? reason,
  }) async {
    final response = await ApiService.authenticatedPut(
      '/api/admin/reviews/$reviewId/moderate',
      {
        'status': status,
        'reason': reason,
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<List<Map<String, dynamic>>> fetchPricingRules() {
    return _fetchObjectList('/api/admin/pricing-rules');
  }

  Future<Map<String, dynamic>> createPricingRule({
    required String name,
    required String serviceType,
    String? city,
    required double coefficient,
    Map<String, dynamic>? conditions,
    bool enabled = true,
  }) async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/pricing-rules',
      {
        'name': name,
        'serviceType': serviceType,
        'city': city,
        'coefficient': coefficient,
        'conditions': conditions ?? const <String, dynamic>{},
        'enabled': enabled,
      },
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs() {
    return _fetchObjectList('/api/admin/logs');
  }

  Future<List<Map<String, dynamic>>> fetchCrashReports() {
    return _fetchObjectList('/api/admin/errors');
  }

  Future<List<Map<String, dynamic>>> fetchCapacityAlerts() {
    return _fetchObjectList('/api/admin/capacity-alerts');
  }

  Future<Map<String, dynamic>> generateShadowDevSuggestion(
    String crashId,
  ) async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/errors/$crashId/shadow-dev',
      const <String, dynamic>{},
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<Map<String, dynamic>> impersonateUser({
    required String userId,
    required String reason,
  }) async {
    final response = await ApiService.authenticatedPost(
      '/api/admin/impersonate/$userId',
      {'reason': reason},
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeObject(response.body);
  }

  Future<List<Map<String, dynamic>>> _fetchObjectList(String endpoint) async {
    final response = await ApiService.authenticatedGet(
      endpoint,
      authService: _authService,
    );
    _ensureSuccess(response.statusCode, response.body);
    return _decodeList(response.body)
        .map((item) => _asObject(item))
        .toList(growable: false);
  }

  void _ensureSuccess(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    throw AdminApiException(statusCode, body);
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    return _asObject(decoded);
  }

  List<dynamic> _decodeList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    throw const FormatException('La reponse admin attendue est une liste.');
  }

  Map<String, dynamic> _asObject(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const FormatException('La reponse admin attendue est un objet.');
  }
}

class AdminApiException implements Exception {
  final int statusCode;
  final String body;

  const AdminApiException(this.statusCode, this.body);

  @override
  String toString() => 'AdminApiException($statusCode): $body';
}
