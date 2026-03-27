import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/validation_result.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  String get baseUrl => Env.scrapperUrl;

  Future<ValidationResult> validateSpei({
    required String fecha,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/validate');
    final request = http.MultipartRequest('POST', uri);

    request.fields['fecha_operacion'] = fecha;

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
