import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StealthService {
  StealthService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _stealthSettingsKey = 'stealth_settings_v1';

  Future<StealthSettings> loadLocalSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final jsonString = preferences.getString(_stealthSettingsKey);
    if (jsonString == null) {
      return const StealthSettings();
    }
    try {
      final Map<String, dynamic> map = json.decode(jsonString);
      return StealthSettings.fromMap(map);
    } catch (_) {
      return const StealthSettings();
    }
  }

  Future<void> saveLocalSettings(StealthSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_stealthSettingsKey, json.encode(settings.toMap()));
  }

  Future<StealthSettings> loadRemoteSettings(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    
    final data = snapshot.data();
    if (data == null || data['stealthSettings'] == null) {
      return const StealthSettings();
    }
    
    try {
      final Map<String, dynamic> stealthMap = 
          Map<String, dynamic>.from(data['stealthSettings']);
      return StealthSettings.fromMap(stealthMap);
    } catch (_) {
      return const StealthSettings();
    }
  }

  Future<void> saveRemoteSettings(String uid, StealthSettings settings) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set({
          'stealthSettings': settings.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
