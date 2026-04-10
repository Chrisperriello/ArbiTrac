import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//Storage
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  //Storage
  final FlutterSecureStorage _storage;
  //token
  static const String _authTokenKey = 'auth_token';
  static const String _oddsApiKey = 'odds_api_key_v1';

  //Save
  Future<void> saveAuthToken(String token) {
    return _storage.write(key: _authTokenKey, value: token);
  }

  //Read
  Future<String?> readAuthToken() {
    return _storage.read(key: _authTokenKey);
  }

  //Clear
  Future<void> clearAuthToken() {
    return _storage.delete(key: _authTokenKey);
  }

  Future<void> saveOddsApiKey(String key) {
    return _storage.write(key: _oddsApiKey, value: key);
  }

  Future<String?> readOddsApiKey() {
    return _storage.read(key: _oddsApiKey);
  }

  Future<void> clearOddsApiKey() {
    return _storage.delete(key: _oddsApiKey);
  }
}
