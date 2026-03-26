import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistService {
  WatchlistService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _favoriteOpportunityIdsKey =
      'favorite_opportunity_ids_v1';
  static const String _favoriteSportKeysKey = 'favorite_sport_keys_v1';
  static const String _favoriteOpportunityIdsField = 'favoriteOpportunityIds';
  static const String _favoriteSportKeysField = 'favoriteSportKeys';

  final FirebaseFirestore _firestore;

  Future<Set<String>> loadFavoriteOpportunityIds() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_favoriteOpportunityIdsKey);
    if (values == null) {
      return <String>{};
    }
    return values.toSet();
  }

  Future<void> saveFavoriteOpportunityIds(Set<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _favoriteOpportunityIdsKey,
      ids.toList(growable: false),
    );
  }

  Future<Set<String>> loadFavoriteSportKeys() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_favoriteSportKeysKey);
    if (values == null) {
      return <String>{};
    }
    return values.toSet();
  }

  Future<void> saveFavoriteSportKeys(Set<String> keys) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _favoriteSportKeysKey,
      keys.toList(growable: false),
    );
  }

  Future<Set<String>> loadSyncedFavoriteOpportunityIds({
    required String uid,
    required Set<String> localIds,
  }) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    final remoteIds = _extractStringSet(data?[_favoriteOpportunityIdsField]);
    final merged = <String>{...localIds, ...remoteIds};

    if (merged.length != localIds.length) {
      await saveFavoriteOpportunityIds(merged);
    }
    if (merged.length != remoteIds.length) {
      await _saveRemoteWatchlistFields(uid: uid, opportunityIds: merged);
    }
    return merged;
  }

  Future<Set<String>> loadSyncedFavoriteSportKeys({
    required String uid,
    required Set<String> localKeys,
  }) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    final remoteKeys = _extractStringSet(data?[_favoriteSportKeysField]);
    final merged = <String>{...localKeys, ...remoteKeys};

    if (merged.length != localKeys.length) {
      await saveFavoriteSportKeys(merged);
    }
    if (merged.length != remoteKeys.length) {
      await _saveRemoteWatchlistFields(uid: uid, sportKeys: merged);
    }
    return merged;
  }

  Future<void> saveFavoriteOpportunityIdsForUser({
    required String uid,
    required Set<String> ids,
  }) async {
    await _saveRemoteWatchlistFields(uid: uid, opportunityIds: ids);
  }

  Future<void> saveFavoriteSportKeysForUser({
    required String uid,
    required Set<String> keys,
  }) async {
    await _saveRemoteWatchlistFields(uid: uid, sportKeys: keys);
  }

  Set<String> _extractStringSet(Object? rawValue) {
    if (rawValue is! List<dynamic>) {
      return <String>{};
    }
    return rawValue
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<void> _saveRemoteWatchlistFields({
    required String uid,
    Set<String>? opportunityIds,
    Set<String>? sportKeys,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (opportunityIds != null) {
      payload[_favoriteOpportunityIdsField] = opportunityIds.toList(
        growable: false,
      );
    }
    if (sportKeys != null) {
      payload[_favoriteSportKeysField] = sportKeys.toList(growable: false);
    }
    await _firestore.collection('users').doc(uid).set(
      payload,
      SetOptions(merge: true),
    );
  }
}
