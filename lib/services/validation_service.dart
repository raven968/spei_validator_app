import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/validation_result.dart';
import 'auth_service.dart';

class ValidationService {
  static String get _baseUrl => Env.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Envía el resultado al backend de Laravel para guardarlo en el historial.
  /// Si el usuario no tiene plan Business, el backend responde 403 y se ignora.
  static Future<void> saveResult({
    required ValidationResult result,
    required String fechaOperacion,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/validations'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'is_valid_format': result.isValidFormat,
          'issues': result.issues,
          'extracted_data': result.extractedData,
          'banxico_status': result.banxicoStatus,
          'fecha_operacion': fechaOperacion,
        }),
      );
      // 403 = plan Pro (sin historial) → se ignora silenciosamente
    } catch (_) {
      // Error de red → no bloqueamos la experiencia del usuario
    }
  }

  /// Obtiene el historial de validaciones (solo plan Business).
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/validations'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    if (response.statusCode == 403) {
      throw Exception('El historial requiere el plan Business');
    }
    throw Exception('Error al obtener historial');
  }
}
