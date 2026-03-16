import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _cacheKeyPrefix = 'user_display_name_v1_';

  Future<String> loadDisplayName({
    required String uid,
    required String fallbackEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cacheKeyPrefix$uid';
    final cachedValue = prefs.getString(cacheKey);

    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    final remoteName = _extractDisplayName(data);
    if (remoteName != null) {
      await prefs.setString(cacheKey, remoteName);
      return remoteName;
    }

    if (cachedValue != null && cachedValue.trim().isNotEmpty) {
      return cachedValue.trim();
    }

    final fallback = fallbackEmail.trim().isEmpty
        ? 'Guest User'
        : fallbackEmail.trim();
    await prefs.setString(cacheKey, fallback);
    return fallback;
  }

  String? _extractDisplayName(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final username = data['username'] as String?;
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    final displayName = data['displayName'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    return null;
  }
}
