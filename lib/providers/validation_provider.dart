import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/validation_result.dart';
import '../services/validation_service.dart';

class ValidationState {
  final File? selectedImage;
  final String date;
  final bool isLoading;
  final ValidationResult? result;
  final String? errorMessage;

  const ValidationState({
    this.selectedImage,
    this.date = '',
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  ValidationState copyWith({
    File? selectedImage,
    String? date,
    bool? isLoading,
    ValidationResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
    bool clearImage = false,
  }) {
    return ValidationState(
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      date: date ?? this.date,
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ValidationNotifier extends Notifier<ValidationState> {
  @override
  ValidationState build() => const ValidationState();

  void setImage(File? image) {
    state = state.copyWith(
      selectedImage: image,
      clearResult: true,
      clearError: true,
      clearImage: image == null,
    );
  }

  void setDate(String date) {
    state = state.copyWith(date: date);
  }

  Future<void> validate() async {
    if (state.selectedImage == null) return;

    state = state.copyWith(
        isLoading: true, clearResult: true, clearError: true);

    try {
      final result = await ref.read(validationServiceProvider).validateSpei(
            fecha: state.date,
            imageFile: state.selectedImage!,
          );
      state = state.copyWith(result: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      );
    }
  }
}

final validationProvider =
    NotifierProvider<ValidationNotifier, ValidationState>(
  () => ValidationNotifier(),
);
