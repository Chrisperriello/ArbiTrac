import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static final RegExp _oddsApiKeyPattern = RegExp(r'^[A-Za-z0-9]{32}$');
  static String? _runtimeOddsApiKey;

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static bool isValidOddsApiKeyFormat(String key) {
    final normalized = key.trim();
    return _oddsApiKeyPattern.hasMatch(normalized);
  }

  static void setRuntimeOddsApiKey(String key) {
    final normalized = key.trim();
    if (!isValidOddsApiKeyFormat(normalized)) {
      throw ArgumentError.value(
        key,
        'key',
        'Odds API key must be a 32-character alphanumeric string.',
      );
    }
    _runtimeOddsApiKey = normalized;
  }

  //Config for getting the api key
  static String get oddsApiKey {
    final runtimeKey = _runtimeOddsApiKey;
    if (runtimeKey != null && runtimeKey.isNotEmpty) {
      return runtimeKey;
    }
    final key = dotenv.env['ODDS_API_KEY'];
    if (key == null || key.isEmpty || key == 'replace_with_api_key') {
      throw StateError('ODDS_API_KEY is missing in .env');
    }
    return key;
  }
}
