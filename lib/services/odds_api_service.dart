import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rational/rational.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

class OddsApiService {
  static final Decimal _one = Decimal.fromInt(1);
  static final Decimal _zero = Decimal.fromInt(0);
  static final Decimal _hundred = Decimal.fromInt(100);
  static const int _scaleOnInfinitePrecision = 12;
  static const String _sportsCacheKey = 'odds_api_cache_sports';
  static const String _oddsCacheKey = 'odds_api_cache_odds';
  static const String _coreMarkets = 'h2h,spreads,totals';
  static const String _outrightsMarket = 'outrights';

  OddsApiService({
    SharedPreferences? preferences,
    this.cacheTtl = const Duration(minutes: 5),
    this.refreshInterval = const Duration(minutes: 5),
    http.Client? client,
  }) : _preferences = preferences,
       _client = client ?? http.Client();

  final SharedPreferences? _preferences;
  final Duration cacheTtl;
  final Duration refreshInterval;
  final http.Client _client;

  void _log(String message) {
    debugPrint('[OddsApiService] $message');
  }

  Future<List<Map<String, dynamic>>> fetchSports({
    bool forceRefresh = false,
  }) async {
    _log('fetchSports(forceRefresh: $forceRefresh) start');
    final cached = await _readCache(
      _sportsCacheKey,
      forceRefresh: forceRefresh,
    );
    if (cached != null) {
      _log('fetchSports cache hit: ${cached.length} records');
      return cached;
    }
    _log('fetchSports cache miss');

    final remote = await _fetchSportsFromOddsApi();
    if (remote != null) {
      await _writeCache(_sportsCacheKey, remote);
      _log('fetchSports api success: ${remote.length} records');
      return remote;
    }
    _log('fetchSports api failed with no cached fallback');
    throw const OddsApiServiceException(
      'Failed to load sports: no cached data and API request failed.',
    );
  }

  Future<List<Map<String, dynamic>>> fetchOdds({
    String? sportKey,
    bool forceRefresh = false,
  }) async {
    _log(
      'fetchOdds(sportKey: ${sportKey ?? 'all'}, forceRefresh: $forceRefresh) start',
    );
    final cached = await _readCache(_oddsCacheKey, forceRefresh: forceRefresh);
    if (cached != null) {
      final normalizedCached = _normalizeOddsPayload(cached);
      final filtered = _filterOddsBySport(normalizedCached, sportKey);
      _log('fetchOdds cache hit: ${filtered.length} events after filtering');
      return filtered;
    }
    _log('fetchOdds cache miss');

    final remote = await _fetchOddsFromOddsApi();
    if (remote != null) {
      await _writeCache(_oddsCacheKey, remote);
      final normalizedRemote = _normalizeOddsPayload(remote);
      final filtered = _filterOddsBySport(normalizedRemote, sportKey);
      _log('fetchOdds api success: ${filtered.length} events after filtering');
      return filtered;
    }
    _log('fetchOdds api failed with no cached fallback');
    throw const OddsApiServiceException(
      'Failed to load odds: no cached data and API request failed.',
    );
  }

  Stream<List<Map<String, dynamic>>> watchOdds({String? sportKey}) async* {
    _log(
      'watchOdds start (sportKey: ${sportKey ?? 'all'}, refreshInterval: ${refreshInterval.inSeconds}s)',
    );
    final initial = await fetchOdds(sportKey: sportKey, forceRefresh: false);
    _log('watchOdds initial emit: ${initial.length} events');
    yield initial;

    var cycle = 0;
    while (true) {
      await Future<void>.delayed(refreshInterval);
      cycle++;
      _log('watchOdds refresh cycle #$cycle');
      final refreshed = await fetchOdds(sportKey: sportKey, forceRefresh: true);
      _log('watchOdds emit cycle #$cycle: ${refreshed.length} events');
      yield refreshed;
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchSportsFromOddsApi() async {
    final key = _readOddsApiKey();
    if (key == null) {
      _log('sports api key missing');
      return null;
    }

    final uri = Uri.https('api.the-odds-api.com', '/v4/sports', {
      'apiKey': key,
      'all': 'true',
    });

    try {
      _log('GET $uri');
      final response = await _client.get(uri);
      _log(
        'sports response status=${response.statusCode} remaining=${response.headers['x-requests-remaining'] ?? 'unknown'} used=${response.headers['x-requests-used'] ?? 'unknown'}',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(growable: false);
    } catch (_) {
      _log('sports request threw an exception');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchOddsFromOddsApi() async {
    final key = _readOddsApiKey();
    if (key == null) {
      _log('odds api key missing');
      return null;
    }

    final sports = await _fetchSportsFromOddsApi();
    if (sports == null || sports.isEmpty) {
      _log('odds pull aborted: sports list unavailable');
      return null;
    }

    final activeSports = sports
        .where((sport) => sport['active'] == true)
        .map((sport) => Map<String, dynamic>.from(sport))
        .toList(growable: false);
    if (activeSports.isEmpty) {
      _log('odds pull aborted: no active sports');
      return null;
    }
    _log('odds pull active sports count: ${activeSports.length}');

    final allEvents = <Map<String, dynamic>>[];
    for (final sport in activeSports) {
      final sportKey = sport['key'] as String?;
      if (sportKey == null || sportKey.isEmpty) {
        continue;
      }

      final coreEvents = await _fetchOddsForSportAndMarkets(
        apiKey: key,
        sportKey: sportKey,
        markets: _coreMarkets,
      );
      if (coreEvents.isNotEmpty) {
        allEvents.addAll(coreEvents);
      }

      if (sport['has_outrights'] == true) {
        final outrightEvents = await _fetchOddsForSportAndMarkets(
          apiKey: key,
          sportKey: sportKey,
          markets: _outrightsMarket,
        );
        if (outrightEvents.isNotEmpty) {
          allEvents.addAll(outrightEvents);
        }
      }
    }

    final mergedEvents = _mergeEventsById(allEvents);
    if (mergedEvents.isEmpty) {
      _log('odds pull completed with 0 events');
      return null;
    }
    _log('odds pull completed with ${mergedEvents.length} events total');
    return mergedEvents;
  }

  Future<List<Map<String, dynamic>>> _fetchOddsForSportAndMarkets({
    required String apiKey,
    required String sportKey,
    required String markets,
  }) async {
    final uri = Uri.https('api.the-odds-api.com', '/v4/sports/$sportKey/odds', {
      'apiKey': apiKey,
      'regions': 'us',
      'markets': markets,
      'oddsFormat': 'american',
      'dateFormat': 'iso',
    });
    try {
      _log('GET $uri');
      final response = await _client.get(uri);
      _log(
        'odds response sport=$sportKey markets=$markets status=${response.statusCode} remaining=${response.headers['x-requests-remaining'] ?? 'unknown'} used=${response.headers['x-requests-used'] ?? 'unknown'}',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(growable: false);
    } catch (_) {
      _log('odds request exception for sport=$sportKey markets=$markets');
      return const [];
    }
  }

  List<Map<String, dynamic>> _mergeEventsById(List<Map<String, dynamic>> events) {
    final byId = <String, Map<String, dynamic>>{};
    for (final event in events) {
      final eventId = event['id'] as String?;
      if (eventId == null || eventId.isEmpty) {
        continue;
      }
      byId.putIfAbsent(eventId, () => event);
    }
    return byId.values.toList(growable: false);
  }

  String? _readOddsApiKey() {
    try {
      _log(AppConfig.oddsApiKey);
      return AppConfig.oddsApiKey;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _readCache(
    String key, {
    required bool forceRefresh,
  }) async {
    if (forceRefresh) {
      _log('cache bypassed for key=$key (forceRefresh=true)');
      return null;
    }

    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      _log('cache miss for key=$key (empty)');
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final savedAtMs = decoded['saved_at_ms'] as int?;
    final payload = decoded['data'] as List<dynamic>?;
    if (savedAtMs == null || payload == null) {
      _log('cache invalid for key=$key (missing metadata)');
      return null;
    }

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    if (DateTime.now().difference(savedAt) > cacheTtl) {
      _log('cache stale for key=$key');
      return null;
    }
    _log('cache hit for key=$key');

    return payload
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> _writeCache(String key, List<Map<String, dynamic>> data) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final payload = {
      'saved_at_ms': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    await prefs.setString(key, jsonEncode(payload));
    _log('cache write key=$key count=${data.length}');
  }

  List<Map<String, dynamic>> _filterOddsBySport(
    List<Map<String, dynamic>> odds,
    String? sportKey,
  ) {
    if (sportKey == null || sportKey.isEmpty) {
      return odds;
    }
    return odds
        .where((item) => item['sport_key'] == sportKey)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _normalizeOddsPayload(
    List<Map<String, dynamic>> odds,
  ) {
    return odds
        .map((event) {
          final nextEvent = Map<String, dynamic>.from(event);
          final bookmakers = (event['bookmakers'] as List<dynamic>? ?? [])
              .map((bookmaker) {
                final nextBookmaker = Map<String, dynamic>.from(
                  bookmaker as Map,
                );
                final markets =
                    (nextBookmaker['markets'] as List<dynamic>? ?? [])
                        .map((market) {
                          final nextMarket = Map<String, dynamic>.from(
                            market as Map,
                          );
                          final outcomes =
                              (nextMarket['outcomes'] as List<dynamic>? ?? [])
                                  .map((outcome) {
                                    final nextOutcome =
                                        Map<String, dynamic>.from(
                                          outcome as Map,
                                        );
                                    final existingDecimal = _parseToDecimal(
                                      nextOutcome['decimal_price'],
                                    );
                                    if (existingDecimal != null) {
                                      nextOutcome['decimal_price'] =
                                          existingDecimal;
                                      return nextOutcome;
                                    }
                                    final decimalFromPrice =
                                        _americanOddsToDecimalOdds(
                                          nextOutcome['price'],
                                        );
                                    if (decimalFromPrice != null) {
                                      nextOutcome['decimal_price'] =
                                          decimalFromPrice;
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
          nextEvent['bookmakers'] = bookmakers;
          return nextEvent;
        })
        .toList(growable: false);
  }

  Decimal? _americanOddsToDecimalOdds(dynamic price) {
    final parsedPrice = _parseToDecimal(price);
    if (parsedPrice == null) {
      return null;
    }

    final absolutePrice = parsedPrice < _zero ? -parsedPrice : parsedPrice;
    if (absolutePrice >= _hundred) {
      if (parsedPrice > _zero) {
        return _one + _toDecimal(parsedPrice / _hundred);
      }
      return _one + _toDecimal(_hundred / absolutePrice);
    }

    if (parsedPrice > _one) {
      return parsedPrice;
    }
    return null;
  }

  Decimal? _parseToDecimal(dynamic value) {
    return switch (value) {
      Decimal decimalValue => decimalValue,
      num numberValue => Decimal.parse(numberValue.toString()),
      String stringValue => _parseDecimalString(stringValue),
      _ => null,
    };
  }

  Decimal? _parseDecimalString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.startsWith('+') ? trimmed.substring(1) : trimmed;
    if (!_decimalPattern.hasMatch(normalized)) {
      return null;
    }
    return Decimal.parse(normalized);
  }

  static final RegExp _decimalPattern = RegExp(r'^-?\d+(\.\d+)?$');

  Decimal _toDecimal(Rational value) {
    return value.toDecimal(scaleOnInfinitePrecision: _scaleOnInfinitePrecision);
  }
}

class OddsApiServiceException implements Exception {
  const OddsApiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
