import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get oddsApiKey {
    final key = dotenv.env['ODDS_API_KEY'];
    if (key == null || key.isEmpty || key == 'replace_with_api_key') {
      throw StateError('ODDS_API_KEY is missing in .env');
    }
    return key;
  }
}
