import 'dart:convert';

import '../models/cart_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class PaymentCheckoutResult {
  final bool isSuccess;
  final bool isPending;
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  const PaymentCheckoutResult({
    required this.isSuccess,
    required this.isPending,
    required this.statusCode,
    required this.message,
    required this.data,
  });
}

class PaymentService {
  Future<PaymentCheckoutResult> checkout({
    required List<CartItem> items,
    required String paymentCode,
    required String paymentLabel,
    required String fullName,
    required String phoneNumber,
    required String email,
    required AuthService authService,
  }) async {
    final token = await authService.getToken();
    if (token == null) {
      return const PaymentCheckoutResult(
        isSuccess: false,
        isPending: false,
        statusCode: 401,
        message: 'Session expiree. Veuillez vous reconnecter.',
        data: null,
      );
    }

    final payload = <String, dynamic>{
      'totalAmount': items.fold<double>(
        0,
        (sum, item) => sum + item.priceValue.toDouble(),
      ),
      'currency': 'XOF',
      'paymentMethod': <String, dynamic>{
        'code': paymentCode,
        'label': paymentLabel,
        'phoneNumber': phoneNumber.trim().isEmpty ? null : phoneNumber.trim(),
        'holderName': fullName.trim().isEmpty ? null : fullName.trim(),
        'email': email.trim().isEmpty ? null : email.trim(),
      },
      'items': items.map(_serializeItem).toList(growable: false),
    };

    try {
      final response = await ApiService.post(
        '/payments/checkout',
        payload,
        token: token,
      );

      final body = _decodeObject(response.body);
      final message = _extractMessage(body) ??
          (response.statusCode == 202
              ? 'Paiement en attente de confirmation.'
              : response.statusCode >= 200 && response.statusCode < 300
                  ? 'Paiement confirme.'
                  : 'Le paiement a echoue.');

      return PaymentCheckoutResult(
        isSuccess: response.statusCode == 200 || response.statusCode == 201,
        isPending: response.statusCode == 202,
        statusCode: response.statusCode,
        message: message,
        data: body,
      );
    } catch (error) {
      return PaymentCheckoutResult(
        isSuccess: false,
        isPending: false,
        statusCode: 500,
        message: 'Erreur de paiement: $error',
        data: null,
      );
    }
  }

  Map<String, dynamic> _serializeItem(CartItem item) {
    return <String, dynamic>{
      'cartItemId': item.id,
      'itemType': item.type,
      'serviceType': item.serviceType ?? item.type,
      'name': item.name,
      'subtitle': item.subtitle,
      'amount': item.priceValue.toDouble(),
      'partnerId': item.partnerId,
      'prestationId': item.prestationId,
      'reservationStart': item.reservationStart?.toUtc().toIso8601String(),
      'reservationEnd': item.reservationEnd?.toUtc().toIso8601String(),
      'metadata': _normalizeJson(item.metadata),
    };
  }

  dynamic _normalizeJson(dynamic value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _normalizeJson(nestedValue),
        ),
      );
    }
    if (value is Iterable) {
      return value.map(_normalizeJson).toList(growable: false);
    }
    return value;
  }

  Map<String, dynamic>? _decodeObject(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  String? _extractMessage(Map<String, dynamic>? body) {
    if (body == null) return null;

    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final error = body['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    return null;
  }
}
