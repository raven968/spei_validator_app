import 'dart:convert';

/// Parsea el body de una respuesta de error de la API.
/// Soporta el formato de Laravel FormRequest (422):
/// ```json
/// {
///   "message": "The given data was invalid.",
///   "errors": {
///     "email": ["The email field is required."],
///     "password": ["The password must be at least 8 characters."]
///   }
/// }
/// ```
String parseApiError(String body, {String fallback = 'Error del servidor'}) {
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;

    // Laravel 422 validation errors
    if (json.containsKey('errors') && json['errors'] is Map) {
      final errors = json['errors'] as Map<String, dynamic>;
      final messages = errors.values
          .expand((v) => v is List ? v : [v])
          .map((m) => m.toString())
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }

    // FastAPI / generic detail
    if (json.containsKey('detail')) return json['detail'].toString();

    // Laravel message field
    if (json.containsKey('message')) return json['message'].toString();

    return fallback;
  } catch (_) {
    return fallback;
  }
}
