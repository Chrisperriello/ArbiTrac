import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static final RegExp _oddsApiKeyPattern = RegExp(r'^[A-Za-z0-9]{32}$');
  static String? _userProvidedOddsApiKey;

  static Future<void> load({String? secureStorageOddsApiKey}) async {
    await dotenv.load(fileName: '.env');
    if (secureStorageOddsApiKey == null) {
      return;
    }
    final normalized = secureStorageOddsApiKey.trim();
    if (isValidOddsApiKeyFormat(normalized)) {
      _userProvidedOddsApiKey = normalized;
    }
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
    _userProvidedOddsApiKey = normalized;
  }

  //Config for getting the api key
  static String get oddsApiKey {
    final userProvidedKey = _userProvidedOddsApiKey;
    if (userProvidedKey != null && userProvidedKey.isNotEmpty) {
      return userProvidedKey;
    }
    final key = dotenv.env['ODDS_API_KEY'];
    if (key == null || key.isEmpty || key == 'replace_with_api_key') {
      throw StateError('ODDS_API_KEY is missing in .env');
    }
    return key;
  }
}
