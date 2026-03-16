import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/validation_result.dart';

class ApiService {
  // Cambiar a la IP de tu máquina si pruebas desde un dispositivo físico
  static const String baseUrl = 'http://localhost:8000';

  static Future<ValidationResult> validateSpei({
    required String fecha,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/validate');

    final request = http.MultipartRequest('POST', uri);

    // Form field: fecha_operacion
    request.fields['fecha_operacion'] = fecha;

    // File field: file
    final fileStream = http.MultipartFile.fromBytes(
      'file',
      await imageFile.readAsBytes(),
      filename: imageFile.path.split('/').last,
    );
    request.files.add(fileStream);

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return ValidationResult.fromJson(json);
    } else {
      throw Exception(
        'Error del servidor (${streamedResponse.statusCode}): $responseBody',
      );
    }
  }
}
