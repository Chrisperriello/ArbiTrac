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
    final favoritesAsync = ref.watch(favoriteOpportunityIdsProvider);
    final sportsByKeyAsync = ref.watch(availableSportsByKeyProvider);
    final favoriteSportKeysAsync = ref.watch(favoriteSportKeysProvider);
    final favoriteIds = favoritesAsync.asData?.value ?? <String>{};
    final sportsByKey = sportsByKeyAsync.asData?.value ?? <String, String>{};
    final favoriteSportKeys =
        favoriteSportKeysAsync.asData?.value ?? <String>{};
    final searchableOpportunities = opportunitiesAsync.asData == null
        ? const <ArbOpportunity>[]
        : _prepareDisplayedOpportunities(
            opportunities: opportunitiesAsync.asData!.value,
            favoriteSportKeys: favoriteSportKeys,
            favoriteOpportunityIds: favoriteIds,
          );

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
        actions: [
          IconButton(
            tooltip: 'Search games',
            onPressed: searchableOpportunities.isEmpty
                ? null
                : () async {
                    final selected = await showSearch<ArbOpportunity?>(
                      context: context,
                      delegate: _OpportunitySearchDelegate(
                        opportunities: searchableOpportunities,
                        favoriteOpportunityIds: favoriteIds,
                        sportsByKey: sportsByKey,
                      ),
                    );
                    if (!context.mounted || selected == null) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected ${selected.eventName}. Detailed view comes in Step 2.6.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ManualArbCalculatorCard(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pinned sports',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 6),
            sportsByKeyAsync.when(
              data: (sportsByKey) {
                final sportEntries = sportsByKey.entries.toList(growable: false)
                  ..sort((a, b) => a.value.compareTo(b.value));
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sportEntries
                      .map(
                        (entry) => FilterChip(
                          label: Text(entry.value),
                          selected: favoriteSportKeys.contains(entry.key),
                          onSelected: (_) async {
                            await ref
                                .read(favoriteSportKeysProvider.notifier)
                                .toggleFavoriteSport(entry.key);
                          },
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Align(
                alignment: Alignment.centerLeft,
                child: Text('Failed to load sports: $error'),
              ),
            ),
            if (favoriteSportKeys.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Showing opportunities for pinned sports only.'),
              ),
            ],
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
                  final displayed = _prepareDisplayedOpportunities(
                    opportunities: opportunities,
                    favoriteSportKeys: favoriteSportKeys,
                    favoriteOpportunityIds: favoriteIds,
                  );
                  if (displayed.isEmpty) {
                    return const Center(
                      child: Text('No arbitrage opportunities right now.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: displayed.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final opportunity = displayed[index];
                      final isFavorite = favoriteIds.contains(
                        opportunity.favoriteId,
                      );
                      return _OpportunityCard(
                        opportunity: opportunity,
                        isFavorite: isFavorite,
                        onFavoritePressed: () async {
                          await ref
                              .read(favoriteOpportunityIdsProvider.notifier)
                              .toggleFavorite(opportunity.favoriteId);
                        },
                      );
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

List<ArbOpportunity> _prepareDisplayedOpportunities({
  required List<ArbOpportunity> opportunities,
  required Set<String> favoriteSportKeys,
  required Set<String> favoriteOpportunityIds,
}) {
  final filtered = favoriteSportKeys.isEmpty
      ? opportunities
      : opportunities
            .where(
              (opportunity) => favoriteSportKeys.contains(opportunity.sportKey),
            )
            .toList(growable: false);
  final prioritized = filtered.toList(growable: false)
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

//The actual opportunity card
class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    required this.isFavorite,
    required this.onFavoritePressed,
  });

  final ArbOpportunity opportunity;
  final bool isFavorite;
  final Future<void> Function() onFavoritePressed;

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
            Text('Sport: ${opportunity.sportKey}'),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: onFavoritePressed,
                  icon: Icon(
                    isFavorite ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isFavorite
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: isFavorite ? 'Unpin game' : 'Pin game',
                ),
                Text(isFavorite ? 'Pinned' : 'Pin to watchlist'),
              ],
            ),
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

//Formatting function for the
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

class _OpportunitySearchDelegate extends SearchDelegate<ArbOpportunity?> {
  _OpportunitySearchDelegate({
    required this.opportunities,
    required this.favoriteOpportunityIds,
    required this.sportsByKey,
  });

  final List<ArbOpportunity> opportunities;
  final Set<String> favoriteOpportunityIds;
  final Map<String, String> sportsByKey;

  @override
  String? get searchFieldLabel => 'Search games, markets, sportsbooks';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildMatchesList(_matchingOpportunities());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildMatchesList(_matchingOpportunities());
  }

  List<ArbOpportunity> _matchingOpportunities() {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return opportunities;
    }
    return opportunities
        .where((opportunity) {
          final sportLabel =
              (sportsByKey[opportunity.sportKey] ?? opportunity.sportKey)
                  .toLowerCase();
          final haystack =
              '${opportunity.eventName} ${opportunity.marketLabel} '
                      '${opportunity.bookmakerA} ${opportunity.bookmakerB} '
                      '${opportunity.sportKey} $sportLabel'
                  .toLowerCase();
          return haystack.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  Widget _buildMatchesList(List<ArbOpportunity> matches) {
    if (matches.isEmpty) {
      return const Center(child: Text('No games match your search.'));
    }
    return ListView.separated(
      itemCount: matches.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final opportunity = matches[index];
        final sportLabel =
            sportsByKey[opportunity.sportKey] ?? opportunity.sportKey;
        final isFavorite = favoriteOpportunityIds.contains(
          opportunity.favoriteId,
        );
        return ListTile(
          title: Text(opportunity.eventName),
          subtitle: Text(
            'Sport: $sportLabel • Market: ${opportunity.marketLabel} • '
            'Books: ${opportunity.bookmakerA}/${opportunity.bookmakerB}',
          ),
          trailing: Icon(
            isFavorite ? Icons.push_pin : Icons.push_pin_outlined,
            size: 18,
          ),
          onTap: () {
            close(context, opportunity);
          },
        );
      },
    );
  }
}
