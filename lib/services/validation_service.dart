import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/validation_result.dart';
import 'auth_service.dart';

final validationServiceProvider = Provider<ValidationService>((ref) {
  return ValidationService(ref.watch(authServiceProvider));
});

class ValidationService {
  final AuthService _authService;

  ValidationService(this._authService);

  String get _baseUrl => Env.apiUrl;

  Future<void> saveResult({
    required ValidationResult result,
    required String fechaOperacion,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/validations'),
        headers: await _authService.authHeaders(),
        body: jsonEncode({
          'is_valid_format': result.isValidFormat,
          'issues': result.issues,
          'extracted_data': result.extractedData,
          'banxico_status': result.banxicoStatus,
          'fecha_operacion': fechaOperacion,
        }),
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/validations'),
      headers: await _authService.authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    throw Exception('Error al obtener historial');
  }
}
