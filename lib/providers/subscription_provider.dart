import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan.dart';
import '../models/subscription_status.dart';
import '../services/subscription_service.dart';

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus?> {
  @override
  Future<SubscriptionStatus?> build() async {
    final service = ref.read(subscriptionServiceProvider);
    try {
      return await service.getStatus();
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionServiceProvider).getStatus(),
    );
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus?>(
  () => SubscriptionNotifier(),
);

final plansProvider = FutureProvider<List<Plan>>((ref) {
  return ref.read(subscriptionServiceProvider).getPlans();
});
