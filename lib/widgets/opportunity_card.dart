import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/arb_engine.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../src/rust/api.dart';
import '../src/rust/risk.dart';
import 'cyber_animations.dart';
import 'risk_monitor.dart';

class CyberOpportunityCard extends ConsumerStatefulWidget {
  const CyberOpportunityCard({
    super.key,
    required this.opportunity,
    required this.isFavorite,
    required this.onOpenDetails,
    required this.onFavoritePressed,
  });

  final ArbOpportunity opportunity;
  final bool isFavorite;
  final VoidCallback onOpenDetails;
  final Future<void> Function() onFavoritePressed;

  @override
  ConsumerState<CyberOpportunityCard> createState() => _CyberOpportunityCardState();
}

class _CyberOpportunityCardState extends ConsumerState<CyberOpportunityCard> {
  MarketType _mapMarketType(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('moneyline') || lower.contains('h2h')) {
      return MarketType.moneyline;
    }
    if (lower.contains('spread') ||
        lower.contains('handicap') ||
        lower.contains('total')) {
      return MarketType.mainTotalHandicapSpread;
    }
    return MarketType.smallMarketTotalHandicap;
  }

  Decimal _roundStake(Decimal stake, int increment) {
    if (increment <= 0) return stake;
    final value = stake.toDouble();
    final rounded = (value / increment).round() * increment;
    return Decimal.parse(rounded.toString());
  }

  void _reportRiskScore(double score) {
    final viewedIds = ref.read(sessionViewedOpportunityIdsProvider);
    if (!viewedIds.contains(widget.opportunity.favoriteId)) {
      // Add to viewed set
      ref.read(sessionViewedOpportunityIdsProvider.notifier).update((state) => {
        ...state,
        widget.opportunity.favoriteId,
      });
      // Add score to average
      ref.read(sessionRiskScoresProvider.notifier).addScore(score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedTextColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.8,
    );
    final opportunitiesAsync = ref.watch(arbOpportunitiesProvider);
    final stealthAsync = ref.watch(stealthSettingsProvider);

    final sameEventOpportunities =
        opportunitiesAsync.asData?.value
            .where((item) => item.eventId == widget.opportunity.eventId)
            .toList(growable: false) ??
        const <ArbOpportunity>[];

    final positiveMarketsByBestProfit = _eventPositiveMarkets(
      sameEventOpportunities,
    );
    final topMarket = positiveMarketsByBestProfit.isEmpty
        ? null
        : positiveMarketsByBestProfit.first;

    final displayPercent = widget.opportunity.profitMarginPercent;
    final displayMarketLabel = widget.opportunity.marketLabel;

    final profitPercent = double.tryParse(displayPercent.toString()) ?? 0;
    final stalenessSeconds = DateTime.now()
        .difference(widget.opportunity.lastUpdatedAt)
        .inSeconds;
    final freshnessColor = stalenessSeconds > 45
        ? colorScheme.error
        : stalenessSeconds > 15
        ? colorScheme.tertiary
        : colorScheme.primary;

    final borderColor = profitPercent >= 3
        ? colorScheme.primary
        : profitPercent >= 1
        ? colorScheme.secondary
        : colorScheme.outline.withValues(alpha: 0.65);

    // Stealth Mode Calculations
    final stealthSettings = stealthAsync.asData?.value ?? const StealthSettings();
    final isStealthActive = stealthSettings.stealthModeEnabled;

    // Use specific investment if set, else fallback to $100
    final investmentInput = ref.watch(
      opportunityInvestmentInputProvider(widget.opportunity.favoriteId),
    );
    final rawInvestment = double.tryParse(investmentInput) ?? 100.0;
    final totalInvestment = Decimal.parse(rawInvestment.toString());

    final rawStakes = ArbEngine.individualStakes(
      decimalOdds: [widget.opportunity.decimalOddsA, widget.opportunity.decimalOddsB],
      totalInvestment: totalInvestment,
    );

    final List<Decimal> finalStakes;
    if (isStealthActive) {
      finalStakes =
          rawStakes
              .map(
                (s) => _roundStake(s, stealthSettings.roundingIncrement),
              )
              .toList(growable: false);
    } else {
      finalStakes = rawStakes;
    }

    // Call Rust Risk Monitor
    final riskOutput = calculateRisk(
      input: RiskInput(
        arbPercent: profitPercent,
        totalInvestment: rawInvestment,
        stakeDistribution: Float64List.fromList(
          finalStakes.map((s) => s.toDouble()).toList(),
        ),
        betsPerDay: stealthSettings.betsPerDay,
        booksCount: stealthSettings.booksCount,
        sportsCount: stealthSettings.sportsCount,
        marketTypes: [_mapMarketType(widget.opportunity.marketLabel)],
      ),
    );

    // Side effect: Add score to session tracking
    if (isStealthActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reportRiskScore(riskOutput.globalScore);
      });
    }

    final card = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.opportunity.eventName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Books ${widget.opportunity.bookmakerA}/${widget.opportunity.bookmakerB}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: mutedTextColor),
                    ),
                  ],
                ),
              ),
              if (isStealthActive)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: RiskMonitor(level: riskOutput.level),
                ),
              IconButton(
                onPressed: widget.onFavoritePressed,
                icon: Icon(
                  widget.isFavorite ? Icons.push_pin : Icons.push_pin_outlined,
                  color: widget.isFavorite ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isStealthActive) ...[
            Text(
              'Stealth Stakes: \$${finalStakes[0].toStringAsFixed(0)} on ${widget.opportunity.bookmakerA} / '
              '\$${finalStakes[1].toStringAsFixed(0)} on ${widget.opportunity.bookmakerB}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            topMarket == null
                ? 'Highest reward market: none'
                : 'Highest reward market: ${topMarket.$1} (${_formatPercent(topMarket.$2)}%)',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: mutedTextColor),
          ),
          if (positiveMarketsByBestProfit.isNotEmpty)
            Text(
              'Positive-return markets: '
              '${positiveMarketsByBestProfit.map((entry) => '${entry.$1} (${_formatPercent(entry.$2)}%)').join(', ')}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedTextColor),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${_formatPercent(displayPercent)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: borderColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                displayMarketLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              CyberPulseIndicator(
                stalenessSeconds: stalenessSeconds,
                pulseColor: freshnessColor,
                tooltipMessage: _formatRelativeHoverTime(
                  widget.opportunity.lastUpdatedAt,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return InkWell(onTap: widget.onOpenDetails, child: card);
  }
}

String _formatPercent(Decimal value) {
  final source = value.toString();
  final decimalIndex = source.indexOf('.');
  if (decimalIndex == -1) {
    return source;
  }
  final maxLength = decimalIndex + 4;
  return source.length <= maxLength ? source : source.substring(0, maxLength);
}

String _formatRelativeHoverTime(DateTime lastUpdatedAt) {
  final totalSeconds = DateTime.now().difference(lastUpdatedAt).inSeconds;
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  if (seconds < 60) {
    return '$seconds second${seconds == 1 ? '' : 's'} ago';
  }
  final minutes = seconds ~/ 60;
  if (minutes < 60) {
    return '$minutes min ago';
  }
  final hours = minutes ~/ 60;
  if (hours < 24) {
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }
  final days = hours ~/ 24;
  return '$days day${days == 1 ? '' : 's'} ago';
}

List<(String, Decimal)> _eventPositiveMarkets(
  List<ArbOpportunity> opportunities,
) {
  final bestByMarket = <String, Decimal>{};
  for (final item in opportunities) {
    if (item.profitMarginPercent <= Decimal.zero) {
      continue;
    }
    final existing = bestByMarket[item.marketLabel];
    if (existing == null || item.profitMarginPercent > existing) {
      bestByMarket[item.marketLabel] = item.profitMarginPercent;
    }
  }
  final entries = bestByMarket.entries
      .map((entry) => (entry.key, entry.value))
      .toList(growable: false);
  entries.sort((a, b) => b.$2.compareTo(a.$2));
  return entries;
}
