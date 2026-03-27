import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/subscription_provider.dart';

class PaymentReturnScreen extends ConsumerStatefulWidget {
  final bool subscribed;
  const PaymentReturnScreen({super.key, required this.subscribed});

  @override
  ConsumerState<PaymentReturnScreen> createState() =>
      _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends ConsumerState<PaymentReturnScreen> {
  String _statusText = 'Verificando pago...';

  @override
  void initState() {
    super.initState();
    if (widget.subscribed) {
      _verifyWithRetry();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/subscription');
      });
    }
  }

  /// Reintenta verificar la suscripción hasta 3 veces.
  /// Stripe puede tardar unos segundos en procesar el webhook.
  Future<void> _verifyWithRetry() async {
    const maxAttempts = 3;
    const delayBetween = Duration(seconds: 3);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (!mounted) return;

      await ref.read(subscriptionProvider.notifier).refresh();
      final status = ref.read(subscriptionProvider).valueOrNull;

      if (status != null && status.isActive) {
        if (mounted) context.go('/');
        return;
      }

      if (attempt < maxAttempts) {
        setState(() => _statusText = 'Confirmando con Stripe... (intento $attempt/$maxAttempts)');
        await Future.delayed(delayBetween);
      }
    }

    // Si después de 3 intentos no se confirma, ir a suscripción
    if (mounted) context.go('/subscription');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00E676)),
            const SizedBox(height: 20),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
