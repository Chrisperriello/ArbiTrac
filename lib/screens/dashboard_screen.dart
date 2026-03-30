import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import 'main_screen.dart';
import 'settings_screen.dart';
import 'sports_event_detail_screen.dart';

//Dashboard Screen
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  //Route name
  static const String routeName = '/dashboard';

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showAllSports = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final usernameAsync = ref.watch(currentUserDisplayNameProvider);
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
          onSelected: (value) async {
            if (value == 'settings') {
              Navigator.of(context).pushNamed(SettingsScreen.routeName);
              return;
            }
            if (value == 'signout') {
              final authService = ref.read(authServiceProvider);
              try {
                await authService.signOut();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pushNamedAndRemoveUntil(
                  MainScreen.routeName,
                  (route) => false,
                );
              } on AuthServiceException catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message)),
                );
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: usernameAsync.when(
                data: (username) => Text(
                  username,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, stackTrace) => const Text('User'),
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
            onPressed: () async {
              if (searchableOpportunities.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No opportunities available to search yet.'),
                  ),
                );
                return;
              }
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
                    'Selected ${selected.eventName}. Tap Details on the card to view market odds.',
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
                final sortedEntries = sportsByKey.entries.toList(growable: false)
                  ..sort((a, b) {
                    final aPinned = favoriteSportKeys.contains(a.key);
                    final bPinned = favoriteSportKeys.contains(b.key);
                    if (aPinned != bPinned) {
                      return aPinned ? -1 : 1;
                    }
                    return a.value.compareTo(b.value);
                  });
                final visibleEntries = _showAllSports
                    ? sortedEntries
                    : sortedEntries.take(5).toList(growable: false);
                final chips = visibleEntries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(entry.value),
                          selected: favoriteSportKeys.contains(entry.key),
                          onSelected: (_) async {
                            await ref
                                .read(favoriteSportKeysProvider.notifier)
                                .toggleFavoriteSport(entry.key);
                          },
                        ),
                      ),
                    )
                    .toList(growable: false);
                final canExpand = sortedEntries.length > 5;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showAllSports)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: chips,
                        ),
                      )
                    else
                      Wrap(spacing: 0, runSpacing: 8, children: chips),
                    if (canExpand)
                      TextButton(
                        onPressed: () {
                          setState(() => _showAllSports = !_showAllSports);
                        },
                        child: Text(_showAllSports ? 'See less' : 'See more'),
                      ),
                  ],
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
                        onOpenDetails: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SportsEventDetailScreen(
                                opportunity: opportunity,
                              ),
                            ),
                          );
                        },
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
    required this.onOpenDetails,
    required this.onFavoritePressed,
  });

  final ArbOpportunity opportunity;
  final bool isFavorite;
  final VoidCallback onOpenDetails;
  final Future<void> Function() onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpenDetails,
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
              Text(
                'Arb %: ${_formatDecimal(opportunity.profitMarginPercent)}%',
              ),
              Text('Market: ${opportunity.marketLabel}'),
              const SizedBox(height: 8),
              _FreshnessIndicator(lastUpdatedAt: opportunity.lastUpdatedAt),
            ],
          ),
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

class _FreshnessIndicator extends StatefulWidget {
  const _FreshnessIndicator({required this.lastUpdatedAt});

  final DateTime lastUpdatedAt;

  @override
  State<_FreshnessIndicator> createState() => _FreshnessIndicatorState();
}

class _FreshnessIndicatorState extends State<_FreshnessIndicator> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final freshnessSeconds = DateTime.now()
        .difference(widget.lastUpdatedAt)
        .inSeconds;
    final freshnessColor = freshnessSeconds <= 15
        ? Colors.green
        : freshnessSeconds <= 45
        ? Colors.orange
        : Colors.red;
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: freshnessColor),
        const SizedBox(width: 8),
        Text('Updated ${freshnessSeconds < 0 ? 0 : freshnessSeconds}s ago'),
      ],
    );
  }
}
