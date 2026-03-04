import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _authTokenKey = 'auth_token';

  Future<void> saveAuthToken(String token) {
    return _storage.write(key: _authTokenKey, value: token);
  }

  Future<String?> readAuthToken() {
    return _storage.read(key: _authTokenKey);
  }

  Future<void> clearAuthToken() {
    return _storage.delete(key: _authTokenKey);
  }
}
