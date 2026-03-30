import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/env.dart';
import '../models/plan.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  final bool fromHome;
  const SubscriptionScreen({super.key, this.fromHome = false});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _loadingCheckout = false;
  String? _error;

  Future<void> _startCheckout(Plan plan) async {
    setState(() {
      _loadingCheckout = true;
      _error = null;
    });

    try {
      final service = ref.read(subscriptionServiceProvider);
      final checkoutUrl = await service.createCheckout(
        planSlug: plan.slug,
        successUrl: 'speivalidator://payment-return?subscribed=true',
        cancelUrl: 'speivalidator://payment-return?subscribed=false',
      );
      await launchUrl(Uri.parse(checkoutUrl),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCheckout = false);
    }
  }

  Future<void> _verifyPayment() async {
    await ref.read(subscriptionProvider.notifier).refresh();
    final status = ref.read(subscriptionProvider).valueOrNull;
    if (!mounted) return;
    if (status != null && status.isActive) {
      context.go('/');
      return;
    }
    setState(() {
      _error =
          'No encontramos una subscripción activa. ¿Ya completaste el pago?';
    });
  }

  Future<void> _openPortal() async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      final url = await service.getBillingPortalUrl(
        returnUrl: '${Env.apiUrl}/up',
      );
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    // GoRouter redirect handles navigation
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(subscriptionProvider);
    final plansAsync = ref.watch(plansProvider);
    final isLoading = statusAsync.isLoading;
    final status = statusAsync.valueOrNull;
    final plans = plansAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: widget.fromHome
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 20),
                onPressed: () => context.pop(),
              ),
              title: const Text('Subscripción',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            )
          : null,
      body: SafeArea(
        child: isLoading
            ? const _SubscriptionSkeleton()
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.fromHome) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Elige tu plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white38, size: 22),
                            tooltip: 'Cerrar sesión',
                            onPressed: _logout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Accede a todas las validaciones SPEI',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 36),
                    ],

                    if (status != null && status.subscribed)
                      _buildActiveSubscriptionCard()
                    else if (plans.isEmpty)
                      _buildEmptyPlans()
                    else
                      ...plans.map((plan) => _buildPlanCard(plan)),

                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      _buildErrorCard(_error!),
                    ],

                    if (status != null && status.subscribed) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: const Color(0xFF0D1B2A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Continuar al app'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    if (!(status?.subscribed ?? false))
                      Center(
                        child: TextButton.icon(
                          onPressed: _verifyPayment,
                          icon: const Icon(Icons.refresh_rounded,
                              color: Color(0xFF448AFF), size: 18),
                          label: const Text(
                            'Ya pagué, verificar subscripción',
                            style: TextStyle(
                              color: Color(0xFF448AFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E676).withValues(alpha: 0.08),
            const Color(0xFF448AFF).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.25),
            width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plan.name.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '\$${plan.formattedPrice}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1),
            ),
            Text(
              '${plan.currency} / ${plan.interval}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ...plan.features.map(_buildFeature),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed:
                    _loadingCheckout ? null : () => _startCheckout(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: const Color(0xFF0D1B2A),
                  disabledBackgroundColor:
                      const Color(0xFF00E676).withValues(alpha: 0.3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: _loadingCheckout
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Color(0xFF0D1B2A), strokeWidth: 2.5))
                    : const Text('Suscribirse ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard() {
    final status = ref.read(subscriptionProvider).valueOrNull;
    final cancelled = status?.cancelled ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cancelled
              ? Colors.orange.withValues(alpha: 0.4)
              : const Color(0xFF00E676).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cancelled
                    ? Icons.warning_amber_rounded
                    : Icons.verified_rounded,
                color: cancelled ? Colors.orange : const Color(0xFF00E676),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                cancelled ? 'Subscripción cancelada' : 'Plan activo',
                style: TextStyle(
                  color:
                      cancelled ? Colors.orange : const Color(0xFF00E676),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (cancelled && status?.endsAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tu acceso termina el ${status!.endsAt!.split('T').first}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _openPortal,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Gestionar subscripción'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF2A3F55)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF00E676), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildEmptyPlans() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A3F55)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: Colors.white24, size: 40),
          const SizedBox(height: 14),
          const Text(
            'No se pudieron cargar los planes',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.invalidate(plansProvider);
              ref.read(subscriptionProvider.notifier).refresh();
            },
            child: const Text('Reintentar',
                style: TextStyle(color: Color(0xFF00E676))),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.red.shade700.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade300, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style:
                    TextStyle(color: Colors.red.shade200, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSkeleton extends StatefulWidget {
  const _SubscriptionSkeleton();

  @override
  State<_SubscriptionSkeleton> createState() => _SubscriptionSkeletonState();
}

class _SubscriptionSkeletonState extends State<_SubscriptionSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final opacity = 0.04 + (_animation.value * 0.08);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _bone(180, 28, opacity),
              const SizedBox(height: 8),
              _bone(220, 14, opacity),
              const SizedBox(height: 36),
              // Plan card skeleton
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity * 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: opacity),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bone(80, 20, opacity),
                    const SizedBox(height: 16),
                    _bone(140, 42, opacity),
                    const SizedBox(height: 4),
                    _bone(100, 14, opacity),
                    const SizedBox(height: 24),
                    _bone(double.infinity, 14, opacity),
                    const SizedBox(height: 10),
                    _bone(double.infinity, 14, opacity),
                    const SizedBox(height: 10),
                    _bone(200, 14, opacity),
                    const SizedBox(height: 28),
                    _bone(double.infinity, 54, opacity,
                        borderRadius: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bone(double width, double height, double opacity,
      {double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
