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
  @override
  void initState() {
    super.initState();
    if (widget.subscribed) {
      _verifyAndRedirect();
    } else {
      // Cancelled — go back to subscription selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/subscription');
      });
    }
  }

  Future<void> _verifyAndRedirect() async {
    await ref.read(subscriptionProvider.notifier).refresh();
    if (!mounted) return;

    final status = ref.read(subscriptionProvider).valueOrNull;
    if (status != null && status.isActive) {
      context.go('/');
    } else {
      context.go('/subscription');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E676)),
            SizedBox(height: 20),
            Text(
              'Verificando pago...',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
