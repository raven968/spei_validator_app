import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/validation_service.dart';

final historyProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(validationServiceProvider).getHistory();
});
