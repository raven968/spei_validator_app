import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'http_client.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider),
  );
});

class ProfileService {
  final ApiClient _client;
  final AuthService _authService;

  ProfileService(this._client, this._authService);

  /// Obtiene el perfil del usuario autenticado.
  Future<User> getProfile() async {
    final response = await _client.get('/auth/me');

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al obtener perfil');
  }

  /// Actualiza nombre y/o contraseña del usuario.
  Future<User> updateProfile({
    String? name,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (password != null) body['password'] = password;

    final response = await _client.put('/auth/profile', body: body);

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      await _authService.updateCachedUser(user);
      return user;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? error['message'] ?? 'Error al actualizar perfil');
  }
}
