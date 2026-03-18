import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPEI Validator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E676),
          secondary: const Color(0xFF448AFF),
          surface: const Color(0xFF1B2838),
          onPrimary: const Color(0xFF0D1B2A),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<Widget> _resolve;

  @override
  void initState() {
    super.initState();
    _resolve = _resolveStartScreen();
  }

  Future<Widget> _resolveStartScreen() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return const LoginScreen();

    try {
      final status = await SubscriptionService.getStatus();
      if (status.isActive) return const HomeScreen();
      return const SubscriptionScreen();
    } catch (_) {
      // Si falla la verificación de subscripción, deja pasar al home
      return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolve,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1B2A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            ),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
