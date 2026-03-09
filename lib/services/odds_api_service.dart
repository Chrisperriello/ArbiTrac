import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/mock_data.dart';

class OddsApiService {
  //This is the class to get connect to the API scraper itself

  OddsApiService({
    SharedPreferences? preferences,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _preferences = preferences;

  //Local Files and timer for each time you fetch data
  final SharedPreferences? _preferences;
  final Duration cacheTtl;

  //This is for local caches so you don't alway have to call the API itself
  //It will store some local data 
  static const String _sportsCacheKey = 'odds_api_cache_sports';
  static const String _oddsCacheKey = 'odds_api_cache_odds';

  //This is to fetch the sports that are cached and that we will be exploring 
  Future<List<Map<String, dynamic>>> fetchSports({
    bool forceRefresh = false,
  }) async {
    final cached = await _readCache(_sportsCacheKey, forceRefresh: forceRefresh);
    if (cached != null) {
      return cached;
    }
    //Use the mock data will be replaced with API calls
    final data = _deepCopy(mockSportsResponse);
    //Write to cache
    await _writeCache(_sportsCacheKey, data);
    return data;
  }

  //This is another fetcher that gets the odds for each thing that you can bet on
  Future<List<Map<String, dynamic>>> fetchOdds({
    String? sportKey,
    bool forceRefresh = false,
  }) async {
    final cached = await _readCache(_oddsCacheKey, forceRefresh: forceRefresh);
    if (cached != null) {
      final normalizedCached = _normalizeOddsPayload(cached);
      return _filterOddsBySport(normalizedCached, sportKey);
    }
    //Normalize the data
    final data = _normalizeOddsPayload(_deepCopy(mockOddsResponse));
    await _writeCache(_oddsCacheKey, data);
    return _filterOddsBySport(data, sportKey);
  }

  Future<List<Map<String, dynamic>>?> _readCache(
    String key, {
    required bool forceRefresh,
  }) async {
    //If we are forcing an API Refresh then null
    if (forceRefresh) {
      return null;
    }

    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    //Decode the Json data, find the time saved and the data 
    final savedAtMs = decoded['saved_at_ms'] as int?;
    final payload = decoded['data'] as List<dynamic>?;

    if (savedAtMs == null || payload == null) {
      return null;
    }

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    // If the data is stale null
    if (DateTime.now().difference(savedAt) > cacheTtl) {
      return null;
    }
    //If the cache is valid then return a list 
    return payload
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  //This writes the sata to the shared prefernecs 
  Future<void> _writeCache(String key, List<Map<String, dynamic>> data) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final payload = {
      'saved_at_ms': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    await prefs.setString(key, jsonEncode(payload));
  }

  //deep copies the data so we don't change the data by accidenet
  List<Map<String, dynamic>> _deepCopy(List<Map<String, dynamic>> source) {
    //En
    final encoded = jsonEncode(source);
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  //Filter Function
  List<Map<String, dynamic>> _filterOddsBySport(
    List<Map<String, dynamic>> odds,
    String? sportKey,
  ) {
    //If not filter then return old odds
    if (sportKey == null || sportKey.isEmpty) {
      return odds;
    }
    //Iterate through the list and then 
    return odds
        .where((item) => item['sport_key'] == sportKey)
        .toList(growable: false);
  }


  //This is for normailize the logic of american betting odds
  List<Map<String, dynamic>> _normalizeOddsPayload(
    List<Map<String, dynamic>> odds,
  ) {
    return odds.map((event) {
      //Shallow copy, edits memory 
      final nextEvent = Map<String, dynamic>.from(event);
      final bookmakers = (event['bookmakers'] as List<dynamic>? ?? [])
          .map((bookmaker) {
            //Shallow copy edits memory 
            final nextBookmaker = Map<String, dynamic>.from(bookmaker as Map);
            final markets = (nextBookmaker['markets'] as List<dynamic>? ?? [])
                .map((market) {
                  final nextMarket = Map<String, dynamic>.from(market as Map);
                  final outcomes = (nextMarket['outcomes'] as List<dynamic>? ?? [])
                      .map((outcome) {
                        final nextOutcome = Map<String, dynamic>.from(outcome as Map);
                        //get the odds and convert them from american to Decimal if needed 
                        final decimalPrice = _americanOddsToDecimalOdds(
                          nextOutcome['price'],
                        );
                        if (decimalPrice != null) {
                          nextOutcome['decimal_price'] = decimalPrice;
                        }
                        return nextOutcome;
                      })
                      .toList(growable: false);
                  nextMarket['outcomes'] = outcomes;
                  return nextMarket;
                })
                .toList(growable: false);
            nextBookmaker['markets'] = markets;
            return nextBookmaker;
          })
          .toList(growable: false);
      //Reattch the bookmakers change to orginal list
      nextEvent['bookmakers'] = bookmakers;
      return nextEvent;
    }).toList(growable: false);
  }

  //Helper function to get go from american odds to decimal
  double? _americanOddsToDecimalOdds(dynamic price) {
    final parsedPrice = switch (price) {
      num value => value.toDouble(),
      String value => double.tryParse(value),
      _ => null,
    };
    if (parsedPrice == null || parsedPrice.abs() < 100) {
      return null;
    }
    if (parsedPrice > 0) {
      return 1 + (parsedPrice / 100);
    }
    return 1 + (100 / parsedPrice.abs());
  }
}
