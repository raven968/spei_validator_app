import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../providers/auth_provider.dart';
import 'auth_service.dart';

/// Excepción específica para sesión expirada (401).
class SessionExpiredException implements Exception {
  @override
  String toString() => 'Tu sesión ha expirado. Inicia sesión de nuevo.';
}

/// Cliente HTTP centralizado que inyecta auth headers
/// e intercepta respuestas 401 para limpiar la sesión.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(authServiceProvider), ref);
});

class ApiClient {
  final AuthService _authService;
  final Ref _ref;

  ApiClient(this._authService, this._ref);

  String get _baseUrl => Env.apiUrl;

  /// GET con auth headers.
  Future<http.Response> get(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );
    _checkUnauthorized(response);
    return response;
  }

  /// POST JSON con auth headers.
  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkUnauthorized(response);
    return response;
  }

  /// PUT JSON con auth headers.
  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkUnauthorized(response);
    return response;
  }

  /// POST multipart con auth headers (para subir archivos).
  Future<http.Response> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    required List<http.MultipartFile> files,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw SessionExpiredException();

    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'))
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..fields.addAll(fields)
      ..files.addAll(files);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _checkUnauthorized(response);
    return response;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw SessionExpiredException();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Si el servidor responde 401, limpia la sesión y lanza excepción.
  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      _authService.logout();
      // Invalida el authProvider para que GoRouter redirija a /login
      _ref.invalidate(authProvider);
      throw SessionExpiredException();
    }
  }
}
