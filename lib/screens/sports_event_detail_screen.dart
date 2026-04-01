
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/arb_engine.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class SportsEventDetailScreen extends ConsumerStatefulWidget {
  const SportsEventDetailScreen({super.key, required this.opportunity});

  final ArbOpportunity opportunity;

  @override
  ConsumerState<SportsEventDetailScreen> createState() =>
      _SportsEventDetailScreenState();
}

class _SportsEventDetailScreenState
    extends ConsumerState<SportsEventDetailScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      sportsEventDetailProvider(widget.opportunity.eventId),
    );
    final selectedMarketKey = ref.watch(
      selectedMarketKeyProvider(widget.opportunity.eventId),
    );
    final investmentInput = ref.watch(
      opportunityInvestmentInputProvider(widget.opportunity.favoriteId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Event details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: detailAsync.when(
          data: (detail) {
            if (detail == null) {
              return const Center(
                child: Text('Could not load event details for this game.'),
              );
            }
            if (detail.markets.isEmpty) {
              return Center(
                child: Text(
                  'No market data available for ${detail.eventName}.',
                ),
              );
            }
            final effectiveMarketKey =
                selectedMarketKey ?? detail.markets.first.marketKey;
            final selectedMarket = detail.markets.firstWhere(
              (market) => market.marketKey == effectiveMarketKey,
              orElse: () => detail.markets.first,
            );
            final marketReturns = _summarizePositiveMarketReturns(detail.markets);
            final topMarket = marketReturns.isEmpty ? null : marketReturns.first;
            final stakeGuidance = _calculateMarketStakeGuidance(
              selectedMarket: selectedMarket,
              totalInvestmentInput: investmentInput,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.eventName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Line age: ${_formatRelativeAge(widget.opportunity.lastUpdatedAt)}',
                ),
                const SizedBox(height: 4),
                Text('Sport: ${detail.sportKey}'),
                Text('Starts: ${detail.commenceTime.toLocal()}'),
                const SizedBox(height: 12),
                Text(
                  'Investment planner',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  topMarket == null
                      ? 'Highest reward market: none'
                      : 'Highest reward market: ${topMarket.marketLabel} '
                            '(${_formatDecimal(topMarket.profitPercent)}%)',
                ),
                if (marketReturns.isNotEmpty)
                  Text(
                    'Positive-return markets: ${marketReturns.map((item) => '${item.marketLabel} (${_formatDecimal(item.profitPercent)}%)').join(', ')}',
                  ),
                const SizedBox(height: 4),
                Text(
                  'Market: ${selectedMarket.marketLabel} (${selectedMarket.marketKey})',
                ),
                const SizedBox(height: 6),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Total investment (\$)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    ref
                            .read(
                              opportunityInvestmentInputProvider(
                                widget.opportunity.favoriteId,
                              ).notifier,
                            )
                            .state =
                        value;
                  },
                ),
                const SizedBox(height: 8),
                if (stakeGuidance.errorMessage != null)
                  Text(
                    stakeGuidance.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (stakeGuidance.result != null) ...[
                  Text(
                    'Bet \$${_formatDecimal(stakeGuidance.result!.stakeA)} on '
                    '${stakeGuidance.result!.bookmakerA} '
                    'for ${stakeGuidance.result!.betDescriptorA}',
                  ),
                  Text(
                    'Bet \$${_formatDecimal(stakeGuidance.result!.stakeB)} on '
                    '${stakeGuidance.result!.bookmakerB} '
                    'for ${stakeGuidance.result!.betDescriptorB}',
                  ),
                  if (stakeGuidance.result!.lineMismatchNote != null)
                    Text(
                      stakeGuidance.result!.lineMismatchNote!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    'Guaranteed payout: \$${_formatDecimal(stakeGuidance.result!.guaranteedPayout)}',
                  ),
                  Text(
                    'Net profit: \$${_formatDecimal(stakeGuidance.result!.netProfit)}',
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Market'),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedMarket.marketKey,
                      onChanged: (nextValue) {
                        if (nextValue == null) {
                          return;
                        }
                        ref
                                .read(
                                  selectedMarketKeyProvider(
                                    widget.opportunity.eventId,
                                  ).notifier,
                                )
                                .state =
                            nextValue;
                      },
                      items: detail.markets
                          .map(
                            (market) => DropdownMenuItem<String>(
                              value: market.marketKey,
                              child: Text(market.marketLabel),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: selectedMarket.bookmakerOdds.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final bookmaker = selectedMarket.bookmakerOdds[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookmaker.bookmakerTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Updated: ${bookmaker.lastUpdatedAt.toLocal()}',
                              ),
                              const SizedBox(height: 8),
                              ...bookmaker.outcomes.map((outcome) {
                                final pointSuffix = outcome.point == null
                                    ? ''
                                    : ' (line ${_formatDecimal(outcome.point!)})';
                                return Text(
                                  '${outcome.name}: '
                                  '${outcome.decimalOdds == null ? 'N/A' : _formatDecimal(outcome.decimalOdds!)}'
                                  '$pointSuffix',
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Failed to load event details: $error')),
        ),
      ),
    );
  }
}

String _formatDecimal(Decimal value) {
  final source = value.toString();
  final decimalIndex = source.indexOf('.');
  if (decimalIndex == -1) {
    return source;
  }
  final maxLength = decimalIndex + 3;
  if (source.length <= maxLength) {
    return source;
  }
  return source.substring(0, maxLength);
}

String _formatRelativeAge(DateTime lastUpdatedAt) {
  final seconds = DateTime.now().difference(lastUpdatedAt).inSeconds;
  if (seconds < 60) {
    return '${seconds < 0 ? 0 : seconds}s';
  }
  final minutes = seconds ~/ 60;
  if (minutes < 60) {
    return '${minutes}m';
  }
  final hours = minutes ~/ 60;
  if (hours < 24) {
    return '$hours hr';
  }
  final days = hours ~/ 24;
  return '$days day${days == 1 ? '' : 's'}';
}

_OpportunityStakeGuidance _calculateMarketStakeGuidance({
  required SportsEventMarketDetail selectedMarket,
  required String totalInvestmentInput,
}) {
  final parsedInvestment = Decimal.tryParse(totalInvestmentInput.trim());
  final zero = Decimal.fromInt(0);
  if (totalInvestmentInput.trim().isEmpty) {
    return const _OpportunityStakeGuidance();
  }
  if (parsedInvestment == null || parsedInvestment <= zero) {
    return const _OpportunityStakeGuidance(
      errorMessage: 'Enter an investment greater than 0.',
    );
  }

  final bestByOutcome = <String, _OutcomeBookOdds>{};
  for (final bookmaker in selectedMarket.bookmakerOdds) {
    for (final outcome in bookmaker.outcomes) {
      final odds = outcome.decimalOdds;
      final name = outcome.name.trim();
      if (odds == null || name.isEmpty) {
        continue;
      }
      final existing = bestByOutcome[name];
      if (existing == null || odds > existing.odds) {
        bestByOutcome[name] = _OutcomeBookOdds(
          outcomeName: name,
          bookmakerTitle: bookmaker.bookmakerTitle,
          odds: odds,
          point: outcome.point,
        );
      }
    }
  }

  final bestQuotes = bestByOutcome.values.toList(growable: false);
  if (bestQuotes.length != 2) {
    return const _OpportunityStakeGuidance(
      errorMessage:
          'Planner supports 2-outcome markets. Select a market with exactly two outcomes.',
    );
  }

  final stakes = ArbEngine.individualStakes(
    decimalOdds: [bestQuotes[0].odds, bestQuotes[1].odds],
    totalInvestment: parsedInvestment,
  );
  final payoutA = stakes[0] * bestQuotes[0].odds;
  final payoutB = stakes[1] * bestQuotes[1].odds;
  final guaranteedPayout = payoutA < payoutB ? payoutA : payoutB;
  return _OpportunityStakeGuidance(
      result: _OpportunityStakeResult(
        stakeA: stakes[0],
        stakeB: stakes[1],
        betDescriptorA: _formatBetDescriptor(
          marketKey: selectedMarket.marketKey,
          quote: bestQuotes[0],
        ),
        betDescriptorB: _formatBetDescriptor(
          marketKey: selectedMarket.marketKey,
          quote: bestQuotes[1],
        ),
        bookmakerA: bestQuotes[0].bookmakerTitle,
        bookmakerB: bestQuotes[1].bookmakerTitle,
        lineMismatchNote: _lineMismatchNote(
          marketKey: selectedMarket.marketKey,
          quoteA: bestQuotes[0],
          quoteB: bestQuotes[1],
        ),
        guaranteedPayout: guaranteedPayout,
        netProfit: guaranteedPayout - parsedInvestment,
      ),
  );
}

class _OpportunityStakeGuidance {
  const _OpportunityStakeGuidance({this.result, this.errorMessage});

  final _OpportunityStakeResult? result;
  final String? errorMessage;
}

class _OpportunityStakeResult {
  const _OpportunityStakeResult({
    required this.stakeA,
    required this.stakeB,
    required this.betDescriptorA,
    required this.betDescriptorB,
    required this.bookmakerA,
    required this.bookmakerB,
    required this.lineMismatchNote,
    required this.guaranteedPayout,
    required this.netProfit,
  });

  final Decimal stakeA;
  final Decimal stakeB;
  final String betDescriptorA;
  final String betDescriptorB;
  final String bookmakerA;
  final String bookmakerB;
  final String? lineMismatchNote;
  final Decimal guaranteedPayout;
  final Decimal netProfit;
}

class _OutcomeBookOdds {
  const _OutcomeBookOdds({
    required this.outcomeName,
    required this.bookmakerTitle,
    required this.odds,
    required this.point,
  });

  final String outcomeName;
  final String bookmakerTitle;
  final Decimal odds;
  final Decimal? point;
}

String _formatBetDescriptor({
  required String marketKey,
  required _OutcomeBookOdds quote,
}) {
  if (marketKey == 'h2h') {
    return '${quote.outcomeName} moneyline';
  }
  if (marketKey == 'spreads') {
    final line = quote.point == null ? '' : ' ${_signedLine(quote.point!)}';
    return '${quote.outcomeName} spread$line';
  }
  if (marketKey == 'totals') {
    final line = quote.point == null ? '' : ' ${_signedLine(quote.point!)}';
    return '${quote.outcomeName} total$line';
  }
  if (marketKey == 'outrights') {
    return '${quote.outcomeName} outright';
  }
  return quote.outcomeName;
}

String? _lineMismatchNote({
  required String marketKey,
  required _OutcomeBookOdds quoteA,
  required _OutcomeBookOdds quoteB,
}) {
  if (marketKey != 'spreads' && marketKey != 'totals') {
    return null;
  }
  final a = quoteA.point;
  final b = quoteB.point;
  if (a == null || b == null) {
    return null;
  }
  if (a == b || a == -b) {
    return null;
  }
  return 'Note: selected best prices are from different lines '
      '(${_signedLine(a)} vs ${_signedLine(b)}). Verify your stake plan.';
}

String _signedLine(Decimal value) {
  final raw = _formatDecimal(value);
  return value >= Decimal.zero ? '+$raw' : raw;
}

List<_MarketReturnSummary> _summarizePositiveMarketReturns(
  List<SportsEventMarketDetail> markets,
) {
  final one = Decimal.fromInt(1);
  final hundred = Decimal.fromInt(100);
  final summaries = <_MarketReturnSummary>[];
  for (final market in markets) {
    final bestByOutcome = <String, Decimal>{};
    for (final bookmaker in market.bookmakerOdds) {
      for (final outcome in bookmaker.outcomes) {
        final name = outcome.name.trim();
        final odds = outcome.decimalOdds;
        if (name.isEmpty || odds == null) {
          continue;
        }
        final existing = bestByOutcome[name];
        if (existing == null || odds > existing) {
          bestByOutcome[name] = odds;
        }
      }
    }
    final bestOdds = bestByOutcome.values.toList(growable: false);
    if (bestOdds.length != 2) {
      continue;
    }
    final arbSum = ArbEngine.arbitragePercentage(bestOdds);
    if (arbSum >= one) {
      continue;
    }
    summaries.add(
      _MarketReturnSummary(
        marketKey: market.marketKey,
        marketLabel: market.marketLabel,
        profitPercent: (one - arbSum) * hundred,
      ),
    );
  }
  summaries.sort((a, b) => b.profitPercent.compareTo(a.profitPercent));
  return summaries;
}

class _MarketReturnSummary {
  const _MarketReturnSummary({
    required this.marketKey,
    required this.marketLabel,
    required this.profitPercent,
  });

  final String marketKey;
  final String marketLabel;
  final Decimal profitPercent;
}
