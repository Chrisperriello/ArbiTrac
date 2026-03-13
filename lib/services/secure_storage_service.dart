import 'package:flutter_secure_storage/flutter_secure_storage.dart';


//Storage
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  //Storage 
  final FlutterSecureStorage _storage;
  //token
  static const String _authTokenKey = 'auth_token';


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
}
