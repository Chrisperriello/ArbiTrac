import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class DailyRiskHealth extends ConsumerWidget {
  const DailyRiskHealth({super.key});

  Color _getRiskColor(double score) {
    if (score <= 20) return const Color(0xFF1B5E20); // Dark Green
    if (score <= 40) return const Color(0xFF4CAF50); // Light Green
    if (score <= 60) return const Color(0xFFFFEB3B); // Yellow
    if (score <= 80) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  String _getRiskLabel(double score) {
    if (score <= 20) return 'Low';
    if (score <= 40) return 'Low-Mod';
    if (score <= 60) return 'Moderate';
    if (score <= 80) return 'High';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final averageScore = ref.watch(dailyRiskAverageProvider);
    final stealthSettings = ref.watch(stealthSettingsProvider).value;
    
    if (stealthSettings == null || !stealthSettings.stealthModeEnabled) {
      return const SizedBox.shrink();
    }

    final riskColor = _getRiskColor(averageScore);
    final riskLabel = _getRiskLabel(averageScore);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: averageScore / 100,
                  backgroundColor: riskColor.withValues(alpha: 0.1),
                  color: riskColor,
                  strokeWidth: 4,
                ),
              ),
              Text(
                averageScore.toStringAsFixed(0),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daily Risk Health',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Current session status: $riskLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(sessionRiskScoresProvider.notifier).clear();
            },
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Reset session scores',
          ),
        ],
      ),
    );
  }
}
