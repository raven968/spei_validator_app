import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/plan.dart';
import '../models/subscription_status.dart';
import 'api_error_parser.dart';
import 'auth_service.dart';
import 'http_client.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider),
  );
});

class SubscriptionService {
  final ApiClient _client;
  final AuthService _authService;

  SubscriptionService(this._client, this._authService);

  /// Obtiene los planes disponibles (no requiere auth obligatorio).
  Future<List<Plan>> getPlans() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/plans'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al obtener planes');
  }

  /// Obtiene el estado de suscripción del usuario.
  Future<SubscriptionStatus> getStatus() async {
    final response = await _client.get('/subscription/status');

    if (response.statusCode == 200) {
      return SubscriptionStatus.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al obtener estado de subscripción');
  }

  /// Crea una sesión de checkout en Stripe.
  Future<String> createCheckout({
    required String planSlug,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _client.post('/subscription/checkout', body: {
      'plan_slug': planSlug,
      'success_url': successUrl,
      'cancel_url': cancelUrl,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['checkout_url'];
    }
    throw Exception(parseApiError(response.body, fallback: 'Error al iniciar pago'));
  }

  /// Obtiene la URL del portal de facturación de Stripe.
  Future<String> getBillingPortalUrl({required String returnUrl}) async {
    final response = await _client.post('/subscription/portal', body: {
      'return_url': returnUrl,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'];
    }
    throw Exception('Error al abrir portal de facturación');
  }

  /// Cancela la suscripción activa.
  Future<void> cancel() async {
    final response = await _client.post('/subscription/cancel');

    if (response.statusCode != 200) {
      throw Exception(parseApiError(response.body, fallback: 'Error al cancelar subscripción'));
    }
  }

  /// Reanuda una suscripción cancelada.
  Future<void> resume() async {
    final response = await _client.post('/subscription/resume');

    if (response.statusCode != 200) {
      throw Exception(parseApiError(response.body, fallback: 'Error al reanudar subscripción'));
    }
  }
}
