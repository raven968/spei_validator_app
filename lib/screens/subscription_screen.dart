import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/env.dart';
import '../models/plan.dart';
import '../models/subscription_status.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool fromHome;
  const SubscriptionScreen({super.key, this.fromHome = false});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionStatus? _status;
  List<Plan> _plans = [];
  bool _loadingStatus = true;
  bool _loadingCheckout = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loadingStatus = true;
      _error = null;
    });

    // Cargamos por separado para que un error en uno no bloquee al otro
    SubscriptionStatus? status;
    List<Plan> plans = _plans; // conserva los que ya había
    String? error;

    try {
      status = await SubscriptionService.getStatus();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }

    try {
      plans = await SubscriptionService.getPlans();
    } catch (e) {
      error ??= e.toString().replaceFirst('Exception: ', '');
    }

    setState(() {
      _status = status;
      _plans = plans;
      _error = error;
      _loadingStatus = false;
    });
  }

  Future<void> _startCheckout(Plan plan) async {
    setState(() {
      _loadingCheckout = true;
      _error = null;
    });

    try {
      final checkoutUrl = await SubscriptionService.createCheckout(
        planSlug: plan.slug,
        successUrl: '${Env.apiUrl}/up?subscribed=true',
        cancelUrl: '${Env.apiUrl}/up?subscribed=false',
      );

      await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCheckout = false);
    }
  }

  Future<void> _verifyPayment() async {
    setState(() {
      _loadingStatus = true;
      _error = null;
    });
    try {
      final status = await SubscriptionService.getStatus();
      if (!mounted) return;
      if (status.isActive) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        return;
      }
      setState(() {
        _status = status;
        _loadingStatus = false;
        _error = 'No encontramos una subscripción activa. ¿Ya completaste el pago?';
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingStatus = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openPortal() async {
    try {
      final url = await SubscriptionService.getBillingPortalUrl(
        returnUrl: '${Env.apiUrl}/up',
      );
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: widget.fromHome
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Subscripción',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white38, size: 22),
                  tooltip: 'Cerrar sesión',
                  onPressed: _logout,
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: _loadingStatus
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676)))
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

                    // ── Contenido principal ──
                    if (_status != null && _status!.subscribed)
                      _buildActiveSubscriptionCard()
                    else if (_plans.isEmpty)
                      _buildEmptyPlans()
                    else
                      ..._plans.map((plan) => _buildPlanCard(plan)),

                    // ── Error ──
                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      _buildErrorCard(_error!),
                    ],

                    // ── Continuar si ya está suscrito ──
                    if (_status != null && _status!.subscribed) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                            (_) => false,
                          ),
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

                    // ── Verificar pago ──
                    if (!(_status?.subscribed ?? false))
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
            color: const Color(0xFF00E676).withValues(alpha: 0.25), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                onPressed: _loadingCheckout ? null : () => _startCheckout(plan),
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
    final cancelled = _status?.cancelled ?? false;
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
                cancelled ? Icons.warning_amber_rounded : Icons.verified_rounded,
                color: cancelled ? Colors.orange : const Color(0xFF00E676),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                cancelled ? 'Subscripción cancelada' : 'Plan activo',
                style: TextStyle(
                  color: cancelled ? Colors.orange : const Color(0xFF00E676),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (cancelled && _status?.endsAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tu acceso termina el ${_status!.endsAt!.split('T').first}',
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14))),
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
          const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 40),
          const SizedBox(height: 14),
          const Text(
            'No se pudieron cargar los planes',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _load,
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
          Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: Colors.red.shade200, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
