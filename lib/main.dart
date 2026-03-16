import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
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
  late Future<bool> _checkAuth;

  @override
  void initState() {
    super.initState();
    _checkAuth = AuthService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1B2A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            ),
          );
        }
        return snapshot.data == true ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
