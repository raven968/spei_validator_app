import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // URL del backend FastAPI de autenticación
  static const String baseUrl = 'http://localhost:8001';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveSession(data);
      return User.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al iniciar sesión');
    }
  }

  static Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveSession(data);
      return User.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al crear cuenta');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data['access_token']);
    await prefs.setString(_userKey, jsonEncode(data['user']));
  }
}
