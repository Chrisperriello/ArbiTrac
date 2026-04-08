import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/cyber_arb_theme.dart';
import '../core/theme/quant_theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'cyber_animations.dart';
import 'cyber_borders.dart';

class CyberOpportunityCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunitiesAsync = ref.watch(arbOpportunitiesProvider);
    final sameEventOpportunities = opportunitiesAsync.asData?.value
            .where((item) => item.eventId == opportunity.eventId)
            .toList(growable: false) ??
        const <ArbOpportunity>[];
    final positiveMarketsByBestProfit = _eventPositiveMarkets(
      sameEventOpportunities,
    );
    final topMarket = positiveMarketsByBestProfit.isEmpty
        ? null
        : positiveMarketsByBestProfit.first;
    final displayPercent = topMarket?.$2 ?? opportunity.profitMarginPercent;
    final displayMarketLabel = topMarket?.$1 ?? opportunity.marketLabel;

    final profitPercent = double.tryParse(displayPercent.toString()) ?? 0;
    final stalenessSeconds = DateTime.now()
        .difference(opportunity.lastUpdatedAt)
        .inSeconds;
    final freshnessColor = stalenessSeconds > 15
        ? QuantTheme.warning
        : QuantTheme.action;
    final card = Container(
      decoration: cyberArbOpportunityDecoration(profitPercent: profitPercent),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.eventName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onFavoritePressed,
                icon: Icon(
                  isFavorite ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isFavorite ? QuantTheme.action : null,
                ),
              ),
            ],
          ),
          Text(
            'Books ${opportunity.bookmakerA}/${opportunity.bookmakerB}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: CyberArbTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            topMarket == null
                ? 'Highest reward market: none'
                : 'Highest reward market: ${topMarket.$1} (${_formatPercent(topMarket.$2)}%)',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: QuantTheme.textMuted),
          ),
          if (positiveMarketsByBestProfit.isNotEmpty)
            Text(
              'Positive-return markets: '
              '${positiveMarketsByBestProfit.map((entry) => '${entry.$1} (${_formatPercent(entry.$2)}%)').join(', ')}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: QuantTheme.textMuted),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${_formatPercent(displayPercent)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: profitPercent >= 3
                      ? QuantTheme.profit
                      : profitPercent >= 1
                      ? QuantTheme.action
                      : QuantTheme.textMuted,
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
                  opportunity.lastUpdatedAt,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onOpenDetails,
      child: card,
    );
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
