import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String? verifyUrl;
  const VerifyEmailScreen({super.key, this.verifyUrl});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    if (widget.verifyUrl != null) {
      _autoVerify();
    }
  }

  Future<void> _autoVerify() async {
    setState(() => _sending = true);
    try {
      final response = await http.get(Uri.parse(widget.verifyUrl!));
      if (response.statusCode == 200) {
        await _checkVerified();
      } else {
        setState(() {
          _success = false;
          _message = 'No se pudo verificar el correo. Intenta de nuevo.';
        });
      }
    } catch (_) {
      setState(() {
        _success = false;
        _message = 'Error de conexión al verificar.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _message = null;
    });

    try {
      final msg = await ref.read(authServiceProvider).resendVerification();
      setState(() {
        _success = true;
        _message = msg;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _checkVerified() async {
    try {
      final profileService = ref.read(profileServiceProvider);
      final user = await profileService.getProfile();
      if (user.emailVerified) {
        await ref.read(authServiceProvider).updateCachedUser(user);
        ref.invalidate(authProvider);
        if (mounted) context.go('/');
      } else {
        setState(() {
          _success = false;
          _message = 'Tu correo aún no ha sido verificado.';
        });
      }
    } catch (e) {
      setState(() {
        _success = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF448AFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_rounded,
                    color: Color(0xFF448AFF), size: 48),
              ),

              const SizedBox(height: 28),

              const Text(
                'Verifica tu correo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Te enviamos un enlace de verificación a tu correo electrónico. Revisa tu bandeja de entrada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // Check verification button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _checkVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: const Color(0xFF0D1B2A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Ya verifiqué mi correo'),
                ),
              ),

              const SizedBox(height: 14),

              // Resend button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _sending ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF2A3F55)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white54, strokeWidth: 2),
                        )
                      : const Text('Reenviar correo de verificación'),
                ),
              ),

              if (_message != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _success
                        ? const Color(0xFF00E676).withValues(alpha: 0.1)
                        : Colors.red.shade900.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _success
                          ? const Color(0xFF00E676).withValues(alpha: 0.3)
                          : Colors.red.shade700.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _success
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        color: _success
                            ? const Color(0xFF00E676)
                            : Colors.red.shade300,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _success
                                ? const Color(0xFF00E676)
                                : Colors.red.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              TextButton(
                onPressed: _logout,
                child: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
