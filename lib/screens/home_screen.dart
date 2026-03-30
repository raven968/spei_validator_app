import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../providers/validation_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/date_input.dart';
import '../widgets/image_picker_input.dart';
import '../widgets/validation_results.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _dateController = TextEditingController();

  late AnimationController _resultAnimController;
  late Animation<double> _resultFadeAnim;

  @override
  void initState() {
    super.initState();
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _dateController.text = today;
    ref.listenManual(validationProvider, (prev, next) {
      if (next.result != null || next.errorMessage != null) {
        _resultAnimController.forward();
      }
      if (next.isLoading) {
        _resultAnimController.reset();
      }
    });

    // Set initial date in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(validationProvider.notifier).setDate(_dateController.text);
      // Check subscription
      final sub = ref.read(subscriptionProvider);
      sub.whenData((status) {
        if (status != null && !status.isActive && context.mounted) {
          context.go('/subscription');
        }
      });
    });

    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFadeAnim = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  void _onDateChanged() {
    ref.read(validationProvider.notifier).setDate(_dateController.text);
  }

  void _onImageChanged(File? file) {
    ref.read(validationProvider.notifier).setImage(file);
  }

  Future<void> _onRefresh() async {
    ref.invalidate(subscriptionProvider);
    ref.read(validationProvider.notifier).reset();
    _resultAnimController.reset();
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _dateController.text = today;
    ref.read(validationProvider.notifier).setDate(today);
    await ref.read(subscriptionProvider.future);
  }

  Future<void> _validate() async {
    final state = ref.read(validationProvider);
    if (state.selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una imagen primero'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    await ref.read(validationProvider.notifier).validate();
  }

  @override
  Widget build(BuildContext context) {
    final vState = ref.watch(validationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1B2838),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const HomeHeader(),
              const SizedBox(height: 28),

              DateInput(
                controller: _dateController,
                onChanged: _onDateChanged,
              ),
              const SizedBox(height: 22),

              ImagePickerInput(
                selectedImage: vState.selectedImage,
                onImageChanged: _onImageChanged,
              ),
              const SizedBox(height: 28),

              _ValidateButton(
                isLoading: vState.isLoading,
                onPressed: _validate,
              ),
              const SizedBox(height: 24),

              if (vState.result != null || vState.errorMessage != null)
                FadeTransition(
                  opacity: _resultFadeAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(_resultFadeAnim),
                    child: vState.errorMessage != null
                        ? ValidationErrorCard(message: vState.errorMessage!)
                        : ValidationResultCards(result: vState.result!),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _ValidateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ValidateButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          foregroundColor: const Color(0xFF0D1B2A),
          disabledBackgroundColor:
              const Color(0xFF00E676).withValues(alpha: 0.3),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Color(0xFF0D1B2A), strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Validar Transferencia'),
                ],
              ),
      ),
    );
  }
}
