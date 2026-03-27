import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/user.dart';
import 'auth_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(authServiceProvider));
});

class ProfileService {
  final AuthService _authService;

  ProfileService(this._authService);

  String get _baseUrl => Env.apiUrl;

  Future<User> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: await _authService.authHeaders(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al obtener perfil');
  }

  Future<User> updateProfile({
    String? name,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (password != null) body['password'] = password;

    final response = await http.put(
      Uri.parse('$_baseUrl/auth/profile'),
      headers: await _authService.authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      await _authService.updateCachedUser(user);
      return user;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? error['message'] ?? 'Error al actualizar perfil');
  }
}
