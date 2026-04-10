import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import 'cyber_animations.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedTextColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.8,
    );
    final opportunitiesAsync = ref.watch(arbOpportunitiesProvider);
    final sameEventOpportunities =
        opportunitiesAsync.asData?.value
            .where((item) => item.eventId == opportunity.eventId)
            .toList(growable: false) ??
        const <ArbOpportunity>[];
    final positiveMarketsByBestProfit = _eventPositiveMarkets(
      sameEventOpportunities,
    );
    final topMarket = positiveMarketsByBestProfit.isEmpty
        ? null
        : positiveMarketsByBestProfit.first;
    final displayPercent = opportunity.profitMarginPercent;
    final displayMarketLabel = opportunity.marketLabel;

    final profitPercent = double.tryParse(displayPercent.toString()) ?? 0;
    final stalenessSeconds = DateTime.now()
        .difference(opportunity.lastUpdatedAt)
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
                  color: isFavorite ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
          Text(
            'Books ${opportunity.bookmakerA}/${opportunity.bookmakerB}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 6),
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
                  opportunity.lastUpdatedAt,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return InkWell(onTap: onOpenDetails, child: card);
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
