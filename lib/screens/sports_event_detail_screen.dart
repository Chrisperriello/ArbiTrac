import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/arb_engine.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class SportsEventDetailScreen extends ConsumerWidget {
  const SportsEventDetailScreen({super.key, required this.opportunity});

  final ArbOpportunity opportunity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      sportsEventDetailProvider(opportunity.eventId),
    );
    final selectedMarketKey = ref.watch(
      selectedMarketKeyProvider(opportunity.eventId),
    );
    final investmentInput = ref.watch(
      opportunityInvestmentInputProvider(opportunity.favoriteId),
    );
    final stakeGuidance = _calculateStakeGuidance(
      opportunity: opportunity,
      totalInvestmentInput: investmentInput,
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.eventName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text('Sport: ${detail.sportKey}'),
                Text('Starts: ${detail.commenceTime.toLocal()}'),
                const SizedBox(height: 12),
                Text(
                  'Investment planner',
                  style: Theme.of(context).textTheme.titleMedium,
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
                                opportunity.favoriteId,
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
                    'Bet \$${_formatDecimal(stakeGuidance.result!.stakeA)} on ${opportunity.bookmakerA}',
                  ),
                  Text(
                    'Bet \$${_formatDecimal(stakeGuidance.result!.stakeB)} on ${opportunity.bookmakerB}',
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
                                    opportunity.eventId,
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

_OpportunityStakeGuidance _calculateStakeGuidance({
  required ArbOpportunity opportunity,
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
  final stakes = ArbEngine.individualStakes(
    decimalOdds: [opportunity.decimalOddsA, opportunity.decimalOddsB],
    totalInvestment: parsedInvestment,
  );
  final payoutA = stakes[0] * opportunity.decimalOddsA;
  final payoutB = stakes[1] * opportunity.decimalOddsB;
  final guaranteedPayout = payoutA < payoutB ? payoutA : payoutB;
  return _OpportunityStakeGuidance(
    result: _OpportunityStakeResult(
      stakeA: stakes[0],
      stakeB: stakes[1],
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
    required this.guaranteedPayout,
    required this.netProfit,
  });

  final Decimal stakeA;
  final Decimal stakeB;
  final Decimal guaranteedPayout;
  final Decimal netProfit;
}
