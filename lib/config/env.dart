import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiUrl => dotenv.env['API_URL'] ?? 'https://api.speivalidator.com';
  static String get scrapperUrl => dotenv.env['SCRAPPER_URL'] ?? 'https://scrapper.speivalidator.com';
}
