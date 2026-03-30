import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiUrl {
    final base = dotenv.env['API_URL'] ?? 'https://api.speivalidator.com';
    return '$base/v1';
  }
}
