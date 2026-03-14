import 'package:shared_preferences/shared_preferences.dart';

class WatchlistService {
  static const String _favoriteOpportunityIdsKey =
      'favorite_opportunity_ids_v1';
  static const String _favoriteSportKeysKey = 'favorite_sport_keys_v1';

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
}
