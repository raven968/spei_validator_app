import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/plan.dart';
import '../models/subscription_status.dart';
import 'auth_service.dart';

class SubscriptionService {
  static String get _baseUrl => Env.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Plan>> getPlans() async {
    final token = await AuthService.getToken();
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

  static Future<SubscriptionStatus> getStatus() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/subscription/status'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return SubscriptionStatus.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al obtener estado de subscripción');
  }

  static Future<String> createCheckout({
    required String planSlug,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscription/checkout'),
      headers: await _authHeaders(),
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

  static Future<String> getBillingPortalUrl({required String returnUrl}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscription/portal'),
      headers: await _authHeaders(),
      body: jsonEncode({'return_url': returnUrl}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'];
    }
    throw Exception('Error al abrir portal de facturación');
  }

  static Future<void> cancel() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscription/cancel'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al cancelar subscripción');
    }
  }

  static Future<void> resume() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/subscription/resume'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al reanudar subscripción');
    }
  }
}
