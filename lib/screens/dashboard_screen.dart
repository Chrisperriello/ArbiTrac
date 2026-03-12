import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'main_screen.dart';

//Dashboard Screen
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  //Route name
  static const String routeName = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Since it is a consumer if has watches the Tickerprovider to know when to refresh
    ref.watch(dashboardTickerProvider);
    final username =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 'Guest User';
    final sortOption = ref.watch(dashboardSortOptionProvider);
    final opportunitiesAsync = ref.watch(arbOpportunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          tooltip: 'Account',
          onSelected: (value) {
            if (value == 'settings') {
              //App bar popup depeneding on the input this is settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings screen comes in a later step.'),
                ),
              );
            }
            if (value == 'signout') {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(MainScreen.routeName, (route) => false);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                username,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Sign out'),
                ],
              ),
            ),
          ],
          icon: const Icon(Icons.account_circle_outlined),
        ),
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ManualArbCalculatorCard(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Sort by'),
                const SizedBox(width: 12),
                DropdownButton<DashboardSortOption>(
                  value: sortOption,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(dashboardSortOptionProvider.notifier).state =
                          value;
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: DashboardSortOption.highestProfit,
                      child: Text('Highest profit'),
                    ),
                    DropdownMenuItem(
                      value: DashboardSortOption.soonestPayout,
                      child: Text('Soonest payout'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: opportunitiesAsync.when(
                data: (opportunities) {
                  if (opportunities.isEmpty) {
                    return const Center(
                      child: Text('No arbitrage opportunities right now.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: opportunities.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final opportunity = opportunities[index];
                      return _OpportunityCard(opportunity: opportunity);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) {
                  return Center(
                    child: Text('Failed to load opportunities: $error'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//The actual opportunity card
class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity});

  final ArbOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final freshnessSeconds = DateTime.now()
        .difference(opportunity.lastUpdatedAt)
        .inSeconds;
    final freshnessColor = freshnessSeconds <= 15
        ? Colors.green
        : freshnessSeconds <= 45
        ? Colors.orange
        : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              opportunity.eventName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Sportsbooks: ${opportunity.bookmakerA} / ${opportunity.bookmakerB}',
            ),
            Text('Arb %: ${_formatDecimal(opportunity.profitMarginPercent)}%'),
            Text('Market: ${opportunity.marketLabel}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: freshnessColor),
                const SizedBox(width: 8),
                Text(
                  'Updated ${freshnessSeconds < 0 ? 0 : freshnessSeconds}s ago',
                ),
              ],
            ),
          ],
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
