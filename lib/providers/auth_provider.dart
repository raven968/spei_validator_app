import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final authService = ref.read(authServiceProvider);
    final loggedIn = await authService.isLoggedIn();
    if (!loggedIn) return null;
    return authService.getCurrentUser();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final authService = ref.read(authServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => authService.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final authService = ref.read(authServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => authService.register(name: name, email: email, password: password),
    );
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(null);
  }

  void updateUser(User user) {
    state = AsyncData(user);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());
