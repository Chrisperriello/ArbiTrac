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

  Future<String> initializeForNewUser({
    required String uid,
    required String email,
  }) async {
    final normalizedEmail = email.trim();
    final fallbackDisplayName = normalizedEmail.isEmpty
        ? 'Guest User'
        : normalizedEmail;
    await _firestore.collection('users').doc(uid).set({
      'email': normalizedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cacheKeyPrefix$uid';
    await prefs.setString(cacheKey, fallbackDisplayName);
    return fallbackDisplayName;
  }

  Future<void> updateUsername({
    required String uid,
    required String username,
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Username cannot be empty.');
    }

    // Using set(merge: true) creates the document if it doesn't exist
    await _firestore.collection('users').doc(uid).set({
      'username': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cacheKeyPrefix$uid';
    await prefs.setString(cacheKey, trimmed);
  }

  Future<bool> hasUsername(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) return false;
    final username = data['username'] as String?;
    return username != null && username.trim().isNotEmpty;
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
