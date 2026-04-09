import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rational/rational.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../core/config/app_config.dart';
import '../core/utils/arb_engine.dart';
import '../models/models.dart';
import '../services/services.dart';

//gets the oddsApi, it gives the apr is scope
final oddsApiServiceProvider = Provider<OddsApiService>((ref) {
  final oddsApiKey = ref.watch(oddsApiKeyProvider).asData?.value;
  return OddsApiService(apiKeyOverride: oddsApiKey);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final watchlistServiceProvider = Provider<WatchlistService>((ref) {
  return WatchlistService();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final oddsApiKeyProvider = AsyncNotifierProvider<OddsApiKeyNotifier, String?>(
  OddsApiKeyNotifier.new,
);

class OddsApiKeyNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final secureStorage = ref.watch(secureStorageServiceProvider);
    final storedKey = await secureStorage.readOddsApiKey();
    if (storedKey == null || !AppConfig.isValidOddsApiKeyFormat(storedKey)) {
      return null;
    }
    final normalized = storedKey.trim();
    AppConfig.setRuntimeOddsApiKey(normalized);
    return normalized;
  }

  Future<void> setKey(String key) async {
    final normalized = key.trim();
    if (!AppConfig.isValidOddsApiKeyFormat(normalized)) {
      throw ArgumentError.value(
        key,
        'key',
        'Odds API key must be a 32-character alphanumeric string.',
      );
    }
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.saveOddsApiKey(normalized);
    AppConfig.setRuntimeOddsApiKey(normalized);
    state = AsyncData(normalized);
  }
}

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserDisplayNameProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) throw Exception('No user logged in');

  final userProfileService = ref.watch(userProfileServiceProvider);
  return userProfileService.loadDisplayName(
    uid: user.uid,
    fallbackEmail: user.email ?? '',
  );
});

final availableSportsByKeyProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
      final service = ref.watch(oddsApiServiceProvider);
      final sports = await service.fetchSports();
      final byKey = <String, String>{};
      for (final sport in sports) {
        final key = sport['key'] as String? ?? '';
        if (key.isEmpty) {
          continue;
        }
        final title = sport['title'] as String? ?? key;
        byKey[key] = title;
      }
      return byKey;
    });

final rawOddsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) {
  final service = ref.watch(oddsApiServiceProvider);
  return service.watchOdds();
});

final availableBookmakersByKeyProvider =
    Provider.autoDispose<AsyncValue<Map<String, String>>>((ref) {
      final oddsAsync = ref.watch(rawOddsProvider);
      return oddsAsync.whenData((events) {
        final byKey = <String, String>{};
        for (final event in events) {
          final bookmakers = event['bookmakers'] as List<dynamic>? ?? const [];
          for (final bookmakerNode in bookmakers) {
            final bookmaker = Map<String, dynamic>.from(bookmakerNode as Map);
            final key = (bookmaker['key'] as String? ?? '')
                .trim()
                .toLowerCase();
            if (key.isEmpty) {
              continue;
            }
            final title = (bookmaker['title'] as String? ?? key).trim();
            byKey[key] = title.isEmpty ? key : title;
          }
        }
        return byKey;
      });
    });

final selectedMarketKeyProvider = StateProvider.autoDispose
    .family<String?, String>((ref, eventId) => null);

final opportunityInvestmentInputProvider = StateProvider.autoDispose
    .family<String, String>((ref, opportunityId) => '');

final sportsEventDetailProvider = Provider.autoDispose
    .family<AsyncValue<SportsEventDetail?>, String>((ref, eventId) {
      final eventsAsync = ref.watch(rawOddsProvider);
      return eventsAsync.whenData((events) {
        for (final event in events) {
          final id = event['id'] as String? ?? '';
          if (id != eventId) {
            continue;
          }
          return _toSportsEventDetail(event);
        }
        return null;
      });
    });

//Sttragety enums
enum DashboardSortOption { highestProfit, soonestPayout }

enum ManualArbOddsFormat { decimal, american }

enum ManualArbAmericanSign { plus, minus }

final appThemeSelectionProvider =
    AsyncNotifierProvider<AppThemeSelectionNotifier, AppThemeId>(
      AppThemeSelectionNotifier.new,
    );

class AppThemeSelectionNotifier extends AsyncNotifier<AppThemeId> {
  static const String _themeSelectionKey = 'app_theme_selection_v1';

  @override
  Future<AppThemeId> build() async {
    final preferences = await SharedPreferences.getInstance();
    final storedTheme = preferences.getString(_themeSelectionKey);
    return AppThemeIdX.fromStorageValue(storedTheme);
  }

  Future<void> setTheme(AppThemeId themeId) async {
    state = AsyncData(themeId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeSelectionKey, themeId.storageValue);
  }
}

@Deprecated('Use appThemeSelectionProvider instead.')
final appThemeModeProvider = AsyncNotifierProvider<AppThemeModeNotifier, bool>(
  AppThemeModeNotifier.new,
);

class AppThemeModeNotifier extends AsyncNotifier<bool> {
  static const String _themeModeDarkKey = 'app_theme_mode_dark_v1';

  @override
  Future<bool> build() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_themeModeDarkKey) ?? false;
  }

  Future<void> setDarkMode(bool enabled) async {
    state = AsyncData(enabled);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themeModeDarkKey, enabled);
  }
}

//Provider for the if the sort changes
final dashboardSortOptionProvider = StateProvider<DashboardSortOption>((ref) {
  return DashboardSortOption.highestProfit;
});

final manualArbOddsAProvider = StateProvider.autoDispose<String>((ref) => '');
final manualArbOddsBProvider = StateProvider.autoDispose<String>((ref) => '');
final manualArbOddsCProvider = StateProvider.autoDispose<String>((ref) => '');
final manualArbOddsFormatProvider =
    StateProvider.autoDispose<ManualArbOddsFormat>(
      (ref) => ManualArbOddsFormat.decimal,
    );
final manualArbAmericanSignAProvider =
    StateProvider.autoDispose<ManualArbAmericanSign>(
      (ref) => ManualArbAmericanSign.plus,
    );
final manualArbAmericanSignBProvider =
    StateProvider.autoDispose<ManualArbAmericanSign>(
      (ref) => ManualArbAmericanSign.plus,
    );
final manualArbAmericanSignCProvider =
    StateProvider.autoDispose<ManualArbAmericanSign>(
      (ref) => ManualArbAmericanSign.plus,
    );
final manualArbTotalInvestmentProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final favoriteOpportunityIdsProvider =
    AsyncNotifierProvider<FavoriteOpportunityIdsNotifier, Set<String>>(
      FavoriteOpportunityIdsNotifier.new,
    );

class FavoriteOpportunityIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final watchlistService = ref.watch(watchlistServiceProvider);
    final localIds = await watchlistService.loadFavoriteOpportunityIds();
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) {
      return localIds;
    }
    return watchlistService.loadSyncedFavoriteOpportunityIds(
      uid: user.uid,
      localIds: localIds,
    );
  }

  Future<void> toggleFavorite(String opportunityId) async {
    final current = state.asData?.value ?? <String>{};
    final next = Set<String>.from(current);
    if (!next.add(opportunityId)) {
      next.remove(opportunityId);
    }
    state = AsyncData(next);
    final watchlistService = ref.read(watchlistServiceProvider);
    await watchlistService.saveFavoriteOpportunityIds(next);
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      return;
    }
    await watchlistService.saveFavoriteOpportunityIdsForUser(
      uid: user.uid,
      ids: next,
    );
  }
}

final favoriteSportKeysProvider =
    AsyncNotifierProvider<FavoriteSportKeysNotifier, Set<String>>(
      FavoriteSportKeysNotifier.new,
    );

class FavoriteSportKeysNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final watchlistService = ref.watch(watchlistServiceProvider);
    final localKeys = await watchlistService.loadFavoriteSportKeys();
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) {
      return localKeys;
    }
    return watchlistService.loadSyncedFavoriteSportKeys(
      uid: user.uid,
      localKeys: localKeys,
    );
  }

  Future<void> toggleFavoriteSport(String sportKey) async {
    final current = state.asData?.value ?? <String>{};
    final next = Set<String>.from(current);
    if (!next.add(sportKey)) {
      next.remove(sportKey);
    }
    state = AsyncData(next);
    final watchlistService = ref.read(watchlistServiceProvider);
    await watchlistService.saveFavoriteSportKeys(next);
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      return;
    }
    await watchlistService.saveFavoriteSportKeysForUser(
      uid: user.uid,
      keys: next,
    );
  }
}

final favoriteBookmakerKeysProvider =
    AsyncNotifierProvider<FavoriteBookmakerKeysNotifier, Set<String>>(
      FavoriteBookmakerKeysNotifier.new,
    );

class FavoriteBookmakerKeysNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final watchlistService = ref.watch(watchlistServiceProvider);
    final localKeys = await watchlistService.loadFavoriteBookmakerKeys();
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) {
      return localKeys;
    }
    final synced = await watchlistService.loadSyncedFavoriteBookmakerKeys(
      uid: user.uid,
    );
    return synced;
  }

  Future<void> toggleFavoriteBookmaker(String bookmakerKey) async {
    final normalizedKey = bookmakerKey.trim().toLowerCase();
    if (normalizedKey.isEmpty) {
      return;
    }
    final current = state.asData?.value ?? <String>{};
    final next = Set<String>.from(current);
    if (!next.add(normalizedKey)) {
      next.remove(normalizedKey);
    }
    state = AsyncData(next);
    final watchlistService = ref.read(watchlistServiceProvider);
    await watchlistService.saveFavoriteBookmakerKeys(next);
    _syncFavoriteBookmakersToCloud(next);
  }

  Future<void> clearFavoriteBookmakerFilter() async {
    state = const AsyncData(<String>{});
    final watchlistService = ref.read(watchlistServiceProvider);
    await watchlistService.saveFavoriteBookmakerKeys(const <String>{});
    _syncFavoriteBookmakersToCloud(const <String>{});
  }

  void _syncFavoriteBookmakersToCloud(Set<String> keys) {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      return;
    }
    final watchlistService = ref.read(watchlistServiceProvider);
    unawaited(
      watchlistService
          .saveFavoriteBookmakerKeysForUser(uid: user.uid, keys: keys)
          .catchError((Object error, StackTrace stackTrace) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stackTrace,
                library: 'favorite_bookmaker_sync',
                context: ErrorDescription(
                  'while syncing favorite bookmaker keys to Firestore',
                ),
              ),
            );
          }),
    );
  }
}

final manualArbCalculatorProvider =
    Provider.autoDispose<ManualArbCalculatorState>((ref) {
      final one = Decimal.fromInt(1);
      final zero = Decimal.fromInt(0);
      final hundred = Decimal.fromInt(100);
      final totalInvestmentInput = ref.watch(manualArbTotalInvestmentProvider);
      final oddsFormat = ref.watch(manualArbOddsFormatProvider);
      final oddsInputs = <String>[
        ref.watch(manualArbOddsAProvider),
        ref.watch(manualArbOddsBProvider),
        ref.watch(manualArbOddsCProvider),
      ];
      final americanSigns = <ManualArbAmericanSign>[
        ref.watch(manualArbAmericanSignAProvider),
        ref.watch(manualArbAmericanSignBProvider),
        ref.watch(manualArbAmericanSignCProvider),
      ];
      final legLabels = <String>['Bookie A', 'Bookie B', 'Bookie C'];
      final parsedLegs = <_ParsedLeg>[];

      for (var index = 0; index < oddsInputs.length; index++) {
        final trimmed = oddsInputs[index].trim();
        if (trimmed.isEmpty) {
          continue;
        }
        late final Decimal parsedOdds;
        if (oddsFormat == ManualArbOddsFormat.decimal) {
          final parsedDecimalOdds = _parsePositiveDecimal(trimmed);
          if (parsedDecimalOdds == null || parsedDecimalOdds <= one) {
            return const ManualArbCalculatorState(
              errorMessage: 'Enter valid decimal odds greater than 1.0.',
            );
          }
          parsedOdds = parsedDecimalOdds;
        } else {
          final absoluteAmericanOdds = _parsePositiveDecimal(trimmed);
          if (absoluteAmericanOdds == null || absoluteAmericanOdds < hundred) {
            return const ManualArbCalculatorState(
              errorMessage:
                  'Enter American odds as a numeric value of at least 100.',
            );
          }
          final americanToDecimalOdds = _americanToDecimalOdds(
            absoluteOdds: absoluteAmericanOdds,
            sign: americanSigns[index],
          );
          if (americanToDecimalOdds == null || americanToDecimalOdds <= one) {
            return const ManualArbCalculatorState(
              errorMessage: 'Enter valid American odds.',
            );
          }
          parsedOdds = americanToDecimalOdds;
        }
        parsedLegs.add(_ParsedLeg(label: legLabels[index], odds: parsedOdds));
      }

      if (parsedLegs.length < 2) {
        return const ManualArbCalculatorState(
          errorMessage: 'Enter at least two valid odds.',
        );
      }

      final totalInvestment = _parsePositiveDecimal(totalInvestmentInput);
      if (totalInvestment == null || totalInvestment <= zero) {
        return const ManualArbCalculatorState(
          errorMessage: 'Enter a total investment greater than 0.',
        );
      }

      final decimalOdds = parsedLegs
          .map((leg) => leg.odds)
          .toList(growable: false);
      final arbitrageSum = ArbEngine.arbitragePercentage(decimalOdds);
      final isArbitrage = ArbEngine.isArbitrageOpportunity(decimalOdds);
      final stakes = ArbEngine.individualStakes(
        decimalOdds: decimalOdds,
        totalInvestment: totalInvestment,
      );

      final recommendedStakes = <ManualArbRecommendedStake>[];
      final projectedPayouts = <Decimal>[];
      for (var index = 0; index < parsedLegs.length; index++) {
        final leg = parsedLegs[index];
        final stake = stakes[index];
        recommendedStakes.add(
          ManualArbRecommendedStake(
            label: leg.label,
            odds: leg.odds,
            stake: stake,
          ),
        );
        projectedPayouts.add(stake * leg.odds);
      }

      final guaranteedPayout = projectedPayouts.reduce(
        (left, right) => left < right ? left : right,
      );
      final netProfit = guaranteedPayout - totalInvestment;

      return ManualArbCalculatorState(
        result: ManualArbCalculationResult(
          arbitrageSum: arbitrageSum,
          totalInvestment: totalInvestment,
          isArbitrage: isArbitrage,
          recommendedStakes: recommendedStakes,
          guaranteedPayout: guaranteedPayout,
          netProfit: netProfit,
        ),
      );
    });

// Provides all of the arb opportunities
final allArbOpportunitiesProvider =
    Provider.autoDispose<AsyncValue<List<ArbOpportunity>>>((ref) {
      final oddsAsync = ref.watch(rawOddsProvider);
      return oddsAsync.whenData(_extractArbOpportunities);
    });

final arbOpportunitiesProvider =
    Provider.autoDispose<AsyncValue<List<ArbOpportunity>>>((ref) {
      final allOpportunitiesAsync = ref.watch(allArbOpportunitiesProvider);
      final sortOption = ref.watch(dashboardSortOptionProvider);
      final favoriteSportKeys =
          ref.watch(favoriteSportKeysProvider).asData?.value ?? <String>{};
      final favoriteBookmakerKeys =
          ref.watch(favoriteBookmakerKeysProvider).asData?.value ?? <String>{};
      final activeBookmakerKeys = favoriteBookmakerKeys
          .map((key) => key.trim().toLowerCase())
          .where((key) => key.isNotEmpty)
          .toSet();
      final favoriteOpportunityIds =
          ref.watch(favoriteOpportunityIdsProvider).asData?.value ?? <String>{};
      return allOpportunitiesAsync.whenData((allOpportunities) {
        final opportunities = _filterOpportunities(
          opportunities: allOpportunities,
          favoriteSportKeys: favoriteSportKeys,
          activeBookmakerKeys: activeBookmakerKeys,
        );
        opportunities.sort((a, b) {
          switch (sortOption) {
            case DashboardSortOption.highestProfit:
              return b.profitMarginPercent.compareTo(a.profitMarginPercent);
            case DashboardSortOption.soonestPayout:
              return a.commenceTime.compareTo(b.commenceTime);
          }
        });
        return _prioritizeFavoriteOpportunities(
          opportunities,
          favoriteOpportunityIds,
        );
      });
    });

List<ArbOpportunity> _filterOpportunities({
  required List<ArbOpportunity> opportunities,
  required Set<String> favoriteSportKeys,
  required Set<String> activeBookmakerKeys,
}) {
  final bySport = favoriteSportKeys.isEmpty
      ? opportunities
      : opportunities
            .where(
              (opportunity) => favoriteSportKeys.contains(opportunity.sportKey),
            )
            .toList(growable: false);
  if (activeBookmakerKeys.isEmpty) {
    return bySport;
  }
  return bySport
      .where(
        (opportunity) =>
            activeBookmakerKeys.contains(opportunity.bookmakerAKey) ||
            activeBookmakerKeys.contains(opportunity.bookmakerBKey),
      )
      .toList(growable: false);
}

List<ArbOpportunity> _prioritizeFavoriteOpportunities(
  List<ArbOpportunity> opportunities,
  Set<String> favoriteOpportunityIds,
) {
  final prioritized = opportunities.toList(growable: false)
    ..sort((a, b) {
      final aFavorite = favoriteOpportunityIds.contains(a.favoriteId);
      final bFavorite = favoriteOpportunityIds.contains(b.favoriteId);
      if (aFavorite == bFavorite) {
        return 0;
      }
      return aFavorite ? -1 : 1;
    });
  return prioritized;
}

//This function is for actually extracting the opportunites
List<ArbOpportunity> _extractArbOpportunities(
  List<Map<String, dynamic>> events,
) {
  final opportunities = <ArbOpportunity>[];
  final one = Decimal.fromInt(1);
  final hundred = Decimal.fromInt(100);
  final supportedMarkets = <String>{'h2h', 'spreads', 'totals', 'outrights'};

  //Loop through the events
  for (final event in events) {
    //get general data
    final eventId = event['id'] as String? ?? '';
    final sportKey = event['sport_key'] as String? ?? 'unknown_sport';
    final awayTeam = event['away_team'] as String? ?? '';
    final homeTeam = event['home_team'] as String? ?? '';
    final eventName = '$awayTeam vs $homeTeam';
    //Use parse date time function
    final commenceTime =
        _parseDateTime(event['commence_time']) ?? DateTime.now();

    //Get the bookies as a list
    final bookmakers = event['bookmakers'] as List<dynamic>? ?? const [];
    final bestByMarket = <String, Map<String, _OutcomeQuote>>{};

    for (final book in bookmakers) {
      //Create a new map of the bookie
      final bookmaker = Map<String, dynamic>.from(book as Map);
      // get the name
      final bookmakerTitle = bookmaker['title'] as String? ?? 'Unknown';
      final bookmakerKey = _normalizedBookmakerKey(bookmaker);
      final lastUpdatedAt =
          _parseDateTime(bookmaker['last_update']) ?? DateTime.now();
      //Get the markets
      final markets = bookmaker['markets'] as List<dynamic>? ?? const [];

      for (final marketNode in markets) {
        final market = Map<String, dynamic>.from(marketNode as Map);
        final marketKey = market['key'] as String? ?? '';
        //only use supported markets
        if (!supportedMarkets.contains(marketKey)) {
          continue;
        }
        final outcomes = market['outcomes'] as List<dynamic>? ?? const [];
        final marketBest = bestByMarket.putIfAbsent(
          marketKey,
          () => <String, _OutcomeQuote>{},
        );

        for (final outcomeNode in outcomes) {
          final outcome = Map<String, dynamic>.from(outcomeNode as Map);
          //get each name
          final outcomeName = outcome['name'] as String?;
          if (outcomeName == null || outcomeName.isEmpty) {
            continue;
          }
          final decimalPrice = _parseDecimal(outcome['decimal_price']);
          if (decimalPrice == null) {
            continue;
          }
          final existing = marketBest[outcomeName];
          //only give the best outcome, we will use it later
          if (existing == null || decimalPrice > existing.decimalOdds) {
            marketBest[outcomeName] = _OutcomeQuote(
              decimalOdds: decimalPrice,
              bookmakerKey: bookmakerKey,
              bookmakerTitle: bookmakerTitle,
              lastUpdatedAt: lastUpdatedAt,
            );
          }
        }
      }
    }

    for (final entry in bestByMarket.entries) {
      //loop through each market
      final marketKey = entry.key;
      //get each outcome
      final outcomeQuotes = entry.value.values.toList(growable: false);
      if (outcomeQuotes.length != 2) {
        continue;
      }
      // get the odds and see if there is an opportunity
      final firstQuote = outcomeQuotes[0];
      final secondQuote = outcomeQuotes[1];
      final decimalOdds = [firstQuote.decimalOdds, secondQuote.decimalOdds];
      final arbSum = ArbEngine.arbitragePercentage(decimalOdds);
      if (!ArbEngine.isArbitrageOpportunity(decimalOdds)) {
        continue;
      }
      //profit margin
      final profitMarginPercent = (one - arbSum) * hundred;
      //update time
      final freshestUpdate =
          firstQuote.lastUpdatedAt.isAfter(secondQuote.lastUpdatedAt)
          ? firstQuote.lastUpdatedAt
          : secondQuote.lastUpdatedAt;

      // Add the opportunitites to the list
      opportunities.add(
        ArbOpportunity(
          eventId: eventId,
          sportKey: sportKey,
          eventName: eventName,
          marketLabel: _marketLabel(marketKey),
          bookmakerAKey: firstQuote.bookmakerKey,
          bookmakerBKey: secondQuote.bookmakerKey,
          bookmakerA: firstQuote.bookmakerTitle,
          bookmakerB: secondQuote.bookmakerTitle,
          decimalOddsA: firstQuote.decimalOdds,
          decimalOddsB: secondQuote.decimalOdds,
          arbitrageSum: arbSum,
          profitMarginPercent: profitMarginPercent,
          commenceTime: commenceTime,
          lastUpdatedAt: freshestUpdate,
        ),
      );
    }
  }

  return opportunities;
}

SportsEventDetail _toSportsEventDetail(Map<String, dynamic> event) {
  final eventId = event['id'] as String? ?? '';
  final sportKey = event['sport_key'] as String? ?? 'unknown_sport';
  final awayTeam = event['away_team'] as String? ?? '';
  final homeTeam = event['home_team'] as String? ?? '';
  final commenceTime = _parseDateTime(event['commence_time']) ?? DateTime.now();
  final bookmakers = event['bookmakers'] as List<dynamic>? ?? const [];
  final marketsByKey = <String, List<SportsEventBookmakerOdds>>{};

  for (final bookmakerNode in bookmakers) {
    final bookmaker = Map<String, dynamic>.from(bookmakerNode as Map);
    final bookmakerTitle = bookmaker['title'] as String? ?? 'Unknown';
    final lastUpdatedAt =
        _parseDateTime(bookmaker['last_update']) ?? DateTime.now();
    final markets = bookmaker['markets'] as List<dynamic>? ?? const [];

    //This loops through each of the sports books and formats the outcomes and
    //adds each marketentries into the map with the list of parsed outcomes and
    for (final marketNode in markets) {
      final market = Map<String, dynamic>.from(marketNode as Map);
      final marketKey = market['key'] as String? ?? '';
      if (marketKey.isEmpty) {
        continue;
      }
      final outcomes = market['outcomes'] as List<dynamic>? ?? const [];
      final parsedOutcomes = outcomes
          .map((outcomeNode) {
            final outcome = Map<String, dynamic>.from(outcomeNode as Map);
            final name = outcome['name'] as String? ?? 'Unknown';
            final decimalOdds = _parseDecimal(outcome['decimal_price']);
            final point = _parseDecimal(outcome['point']);
            return SportsEventOutcomeOdds(
              name: name,
              decimalOdds: decimalOdds,
              point: point,
            );
          })
          .toList(growable: false);

      final entry = SportsEventBookmakerOdds(
        bookmakerTitle: bookmakerTitle,
        lastUpdatedAt: lastUpdatedAt,
        outcomes: parsedOutcomes,
      );
      final marketEntries = marketsByKey.putIfAbsent(
        marketKey,
        () => <SportsEventBookmakerOdds>[],
      );
      marketEntries.add(entry);
    }
  }

  final markets = marketsByKey.entries
      .map(
        (entry) => SportsEventMarketDetail(
          marketKey: entry.key,
          marketLabel: _marketLabel(entry.key),
          bookmakerOdds: entry.value,
        ),
      )
      .toList(growable: false);

  return SportsEventDetail(
    eventId: eventId,
    sportKey: sportKey,
    awayTeam: awayTeam,
    homeTeam: homeTeam,
    commenceTime: commenceTime,
    markets: markets,
  );
}

//Market label
String _marketLabel(String marketKey) {
  return switch (marketKey) {
    'h2h' => 'Moneyline',
    'spreads' => 'Spread',
    'totals' => 'Total',
    'outrights' => 'Outright',
    _ => marketKey,
  };
}

//Get the time
DateTime? _parseDateTime(dynamic value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String _normalizedBookmakerKey(Map<String, dynamic> bookmaker) {
  final key = (bookmaker['key'] as String? ?? '').trim().toLowerCase();
  if (key.isNotEmpty) {
    return key;
  }
  final title = (bookmaker['title'] as String? ?? '').trim().toLowerCase();
  return title;
}

//Parse the decimal value
Decimal? _parseDecimal(dynamic value) {
  return switch (value) {
    Decimal decimalValue => decimalValue,
    num numberValue => Decimal.parse(numberValue.toString()),
    String stringValue => Decimal.tryParse(stringValue),
    _ => null,
  };
}

//Outcome class for formatting it
class _OutcomeQuote {
  const _OutcomeQuote({
    required this.decimalOdds,
    required this.bookmakerKey,
    required this.bookmakerTitle,
    required this.lastUpdatedAt,
  });

  final Decimal decimalOdds;
  final String bookmakerKey;
  final String bookmakerTitle;
  final DateTime lastUpdatedAt;
}

//Provider for parseing a string into a postive decimal type
Decimal? _parsePositiveDecimal(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return Decimal.tryParse(trimmed);
}

//This is so we have a mainstream way of converting between american and decimal odds
Decimal? _americanToDecimalOdds({
  required Decimal absoluteOdds,
  required ManualArbAmericanSign sign,
}) {
  final one = Decimal.fromInt(1);
  final zero = Decimal.fromInt(0);
  final hundred = Decimal.fromInt(100);
  if (absoluteOdds <= zero) {
    return null;
  }
  //Given the sign then we know how to translate it
  if (sign == ManualArbAmericanSign.plus) {
    return one + _toDecimal(absoluteOdds / hundred);
  }
  return one + _toDecimal(hundred / absoluteOdds);
}

//To decimal converter
Decimal _toDecimal(Rational value) {
  return value.toDecimal(scaleOnInfinitePrecision: 12);
}

//Class for the manual arb calculation
class ManualArbCalculatorState {
  const ManualArbCalculatorState({this.result, this.errorMessage});

  final ManualArbCalculationResult? result;
  final String? errorMessage;
}

//Result for the arb calculation
class ManualArbCalculationResult {
  const ManualArbCalculationResult({
    required this.arbitrageSum,
    required this.totalInvestment,
    required this.isArbitrage,
    required this.recommendedStakes,
    required this.guaranteedPayout,
    required this.netProfit,
  });

  final Decimal arbitrageSum;
  final Decimal totalInvestment;
  final bool isArbitrage;
  final List<ManualArbRecommendedStake> recommendedStakes;
  final Decimal guaranteedPayout;
  final Decimal netProfit;
}

//This is for the recommnedation of what to stake on each
class ManualArbRecommendedStake {
  const ManualArbRecommendedStake({
    required this.label,
    required this.odds,
    required this.stake,
  });

  final String label;
  final Decimal odds;
  final Decimal stake;
}

class _ParsedLeg {
  const _ParsedLeg({required this.label, required this.odds});

  final String label;
  final Decimal odds;
}
