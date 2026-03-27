import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/payment_return_screen.dart';

/// Convierte un Riverpod provider en un ChangeNotifier que GoRouter
/// puede escuchar via refreshListenable, sin recrear el router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Mientras carga auth, no redirigir (preserva deep links)
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      // Permitir /payment-return sin importar auth state,
      // ya que el usuario puede venir de un deep link post-checkout
      if (loc == '/payment-return') {
        return isLoggedIn ? null : '/login';
      }

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (_, state) {
          final fromHome =
              state.uri.queryParameters['fromHome'] == 'true';
          return SubscriptionScreen(fromHome: fromHome);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (_, _) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/payment-return',
        builder: (_, state) {
          final subscribed =
              state.uri.queryParameters['subscribed'] == 'true';
          return PaymentReturnScreen(subscribed: subscribed);
        },
      ),
    ],
    errorBuilder: (_, _) => const Scaffold(
      body: Center(child: Text('Página no encontrada')),
    ),
  );
});
