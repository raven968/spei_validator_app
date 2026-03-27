import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/plan.dart';
import '../models/subscription_status.dart';
import 'auth_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref.watch(authServiceProvider));
});

class SubscriptionService {
  final AuthService _authService;

  SubscriptionService(this._authService);

  String get _baseUrl => Env.apiUrl;

  Future<List<Plan>> getPlans() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/plans'),
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

  Future<SubscriptionStatus> getStatus() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/subscription/status'),
      headers: await _authService.authHeaders(),
    );

    if (response.statusCode == 200) {
      return SubscriptionStatus.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al obtener estado de subscripción');
  }

  Future<String> createCheckout({
    required String planSlug,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscription/checkout'),
      headers: await _authService.authHeaders(),
      body: jsonEncode({
        'plan_slug': planSlug,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['checkout_url'];
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Error al iniciar pago');
  }

  Future<String> getBillingPortalUrl({required String returnUrl}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscription/portal'),
      headers: await _authService.authHeaders(),
      body: jsonEncode({'return_url': returnUrl}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'];
    }
    throw Exception('Error al abrir portal de facturación');
  }

  Future<void> cancel() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscription/cancel'),
      headers: await _authService.authHeaders(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al cancelar subscripción');
    }
  }

  Future<void> resume() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscription/resume'),
      headers: await _authService.authHeaders(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al reanudar subscripción');
    }
  }
}
