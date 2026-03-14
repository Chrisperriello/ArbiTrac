import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rational/rational.dart';

import '../core/utils/arb_engine.dart';
import '../models/models.dart';
import '../services/services.dart';

//gets the oddsApi, it gives the apr is scope
final oddsApiServiceProvider = Provider<OddsApiService>((ref) {
  return OddsApiService();
});

final watchlistServiceProvider = Provider<WatchlistService>((ref) {
  return WatchlistService();
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

//Async Provider, that will give data in the future
final rawOddsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  //Waits for the provider to give out data
  final service = ref.watch(oddsApiServiceProvider);
  //Returns the odds
  return service.fetchOdds();
});

//Sttragety enums
enum DashboardSortOption { highestProfit, soonestPayout }

enum ManualArbOddsFormat { decimal, american }

enum ManualArbAmericanSign { plus, minus }

//Provider for the if the sort changes
final dashboardSortOptionProvider = StateProvider<DashboardSortOption>((ref) {
  return DashboardSortOption.highestProfit;
});

//Ticker for the dashboard to refresh
final dashboardTickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream<int>.periodic(const Duration(seconds: 1), (count) => count);
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
    return watchlistService.loadFavoriteOpportunityIds();
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
    return watchlistService.loadFavoriteSportKeys();
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
final arbOpportunitiesProvider =
    FutureProvider.autoDispose<List<ArbOpportunity>>((ref) async {
      // get the odds
      final oddsPayload = await ref.watch(rawOddsProvider.future);
      //extract the opportunites
      final opportunities = _extractArbOpportunities(oddsPayload);
      //Sort option
      final sortOption = ref.watch(dashboardSortOptionProvider);

      opportunities.sort((a, b) {
        switch (sortOption) {
          case DashboardSortOption.highestProfit:
            return b.profitMarginPercent.compareTo(a.profitMarginPercent);
          case DashboardSortOption.soonestPayout:
            return a.commenceTime.compareTo(b.commenceTime);
        }
      });
      return opportunities;
    });

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
          sportKey: sportKey,
          eventName: eventName,
          marketLabel: _marketLabel(marketKey),
          bookmakerA: firstQuote.bookmakerTitle,
          bookmakerB: secondQuote.bookmakerTitle,
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
    required this.bookmakerTitle,
    required this.lastUpdatedAt,
  });

  final Decimal decimalOdds;
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
