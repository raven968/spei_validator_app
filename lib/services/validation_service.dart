import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/validation_result.dart';
import 'http_client.dart';

final validationServiceProvider = Provider<ValidationService>((ref) {
  return ValidationService(ref.watch(apiClientProvider));
});

class ValidationService {
  final ApiClient _client;

  ValidationService(this._client);

  /// Envía imagen + fecha al API de Laravel, que valida suscripción,
  /// proxy al scraper, guarda historial y devuelve el resultado.
  Future<ValidationResult> validateSpei({
    required String fecha,
    required File imageFile,
  }) async {
    final response = await _client.postMultipart(
      '/validations/validate',
      fields: {'fecha_operacion': fecha},
      files: [
        http.MultipartFile.fromBytes(
          'file',
          await imageFile.readAsBytes(),
          filename: imageFile.path.split('/').last,
        ),
      ],
    );

    if (response.statusCode == 200) {
      return ValidationResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_parseError(response.body, response.statusCode));
  }

  /// Obtiene el historial de validaciones del usuario.
  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await _client.get('/validations');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    throw Exception('Error al obtener historial');
  }

  String _parseError(String body, int statusCode) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail']?.toString() ??
          json['message']?.toString() ??
          'Error del servidor ($statusCode)';
    } catch (_) {
      return 'Error del servidor ($statusCode)';
    }
  }
}
