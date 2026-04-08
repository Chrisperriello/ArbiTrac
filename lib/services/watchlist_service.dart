import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistService {
  WatchlistService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _favoriteOpportunityIdsKey =
      'favorite_opportunity_ids_v1';
  static const String _favoriteSportKeysKey = 'favorite_sport_keys_v1';
  static const String _favoriteBookmakerKeysKey = 'favorite_bookmaker_keys_v1';
  static const String _favoriteBookmakerUpdatedAtMsKey =
      'favorite_bookmaker_keys_updated_at_ms_v1';
  static const String _favoriteOpportunityIdsField = 'favoriteOpportunityIds';
  static const String _favoriteSportKeysField = 'favoriteSportKeys';
  static const String _favoriteBookmakerKeysField = 'favoriteBookmakerKeys';
  static const String _favoriteBookmakerUpdatedAtField =
      'favoriteBookmakerUpdatedAt';

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

  Future<Set<String>> loadFavoriteBookmakerKeys() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_favoriteBookmakerKeysKey);
    if (values == null) {
      return <String>{};
    }
    return values.map((value) => value.trim().toLowerCase()).toSet();
  }

  Future<void> saveFavoriteBookmakerKeys(
    Set<String> keys, {
    DateTime? updatedAt,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final normalizedKeys = keys
        .map((key) => key.trim().toLowerCase())
        .where((key) => key.isNotEmpty);
    final effectiveUpdatedAt = (updatedAt ?? DateTime.now()).toUtc();
    await preferences.setStringList(
      _favoriteBookmakerKeysKey,
      normalizedKeys.toList(growable: false),
    );
    await preferences.setInt(
      _favoriteBookmakerUpdatedAtMsKey,
      effectiveUpdatedAt.millisecondsSinceEpoch,
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

  Future<Set<String>> loadSyncedFavoriteBookmakerKeys({
    required String uid,
  }) async {
    final local = await _loadLocalFavoriteBookmakerData();
    final remote = await _loadRemoteFavoriteBookmakerData(uid: uid);
    final localUpdatedAt =
        local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final remoteUpdatedAt =
        remote.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      await saveFavoriteBookmakerKeys(remote.keys, updatedAt: remoteUpdatedAt);
      return remote.keys;
    }
    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      await saveFavoriteBookmakerKeysForUser(
        uid: uid,
        keys: local.keys,
        updatedAt: localUpdatedAt,
      );
      return local.keys;
    }
    final merged = <String>{...local.keys, ...remote.keys};
    if (merged.length != local.keys.length) {
      await saveFavoriteBookmakerKeys(merged, updatedAt: localUpdatedAt);
    }
    if (merged.length != remote.keys.length) {
      await saveFavoriteBookmakerKeysForUser(
        uid: uid,
        keys: merged,
        updatedAt: localUpdatedAt,
      );
    }
    return merged;
  }

  Future<void> saveFavoriteBookmakerKeysForUser({
    required String uid,
    required Set<String> keys,
    DateTime? updatedAt,
  }) async {
    final effectiveUpdatedAt = (updatedAt ?? DateTime.now()).toUtc();
    final normalizedKeys = keys
        .map((key) => key.trim().toLowerCase())
        .where((key) => key.isNotEmpty);
    await _firestore.collection('users').doc(uid).set({
      _favoriteBookmakerKeysField: normalizedKeys.toList(growable: false),
      _favoriteBookmakerUpdatedAtField: Timestamp.fromDate(effectiveUpdatedAt),
    }, SetOptions(merge: true));
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

  Future<_FavoriteBookmakerData> _loadLocalFavoriteBookmakerData() async {
    final preferences = await SharedPreferences.getInstance();
    final values =
        preferences.getStringList(_favoriteBookmakerKeysKey) ?? const [];
    final updatedAtMs = preferences.getInt(_favoriteBookmakerUpdatedAtMsKey);
    return _FavoriteBookmakerData(
      keys: values
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toSet(),
      updatedAt: updatedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true),
    );
  }

  Future<_FavoriteBookmakerData> _loadRemoteFavoriteBookmakerData({
    required String uid,
  }) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return const _FavoriteBookmakerData(keys: <String>{}, updatedAt: null);
    }
    final rawUpdatedAt = data[_favoriteBookmakerUpdatedAtField];
    final updatedAt = switch (rawUpdatedAt) {
      Timestamp ts => ts.toDate().toUtc(),
      DateTime dt => dt.toUtc(),
      _ => null,
    };
    return _FavoriteBookmakerData(
      keys: _extractStringSet(
        data[_favoriteBookmakerKeysField],
      ).map((key) => key.toLowerCase()).toSet(),
      updatedAt: updatedAt,
    );
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
    await _firestore
        .collection('users')
        .doc(uid)
        .set(payload, SetOptions(merge: true));
  }
}

class _FavoriteBookmakerData {
  const _FavoriteBookmakerData({required this.keys, required this.updatedAt});

  final Set<String> keys;
  final DateTime? updatedAt;
}
