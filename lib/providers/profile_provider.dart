import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

class ProfileNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return ref.read(authServiceProvider).getCurrentUser();
  }

  Future<void> updateProfile({String? name, String? password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(profileServiceProvider).updateProfile(
            name: name,
            password: password,
          );
      ref.read(authProvider.notifier).updateUser(user);
      return user;
    });
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, User?>(() => ProfileNotifier());
