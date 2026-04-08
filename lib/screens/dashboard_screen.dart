import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/quant_theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/opportunity_card.dart';
import 'calculator_screen.dart';
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
    final availableBookmakersByKeyAsync = ref.watch(
      availableBookmakersByKeyProvider,
    );
    final favoriteBookmakerKeysAsync = ref.watch(favoriteBookmakerKeysProvider);
    final favoriteIds = favoritesAsync.asData?.value ?? <String>{};
    final sportsByKey = sportsByKeyAsync.asData?.value ?? <String, String>{};
    final favoriteSportKeys =
        favoriteSportKeysAsync.asData?.value ?? <String>{};
    final favoriteBookmakerKeys =
        favoriteBookmakerKeysAsync.asData?.value ?? <String>{};
    final searchableOpportunities = opportunitiesAsync.asData == null
        ? const <ArbOpportunity>[]
        : opportunitiesAsync.asData!.value;

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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.message)));
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
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(CalculatorScreen.routeName);
                },
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Open Manual Arb Calculator'),
              ),
            ),
            const SizedBox(height: 10),
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
                final sortedEntries =
                    sportsByKey.entries.toList(growable: false)..sort((a, b) {
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Favorite sportsbooks',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 6),
            availableBookmakersByKeyAsync.when(
              data: (bookmakersByKey) {
                if (bookmakersByKey.isEmpty) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No sportsbooks available yet.'),
                  );
                }
                final sortedEntries =
                    bookmakersByKey.entries.toList(growable: false)
                      ..sort((a, b) {
                        final aPinned = favoriteBookmakerKeys.contains(a.key);
                        final bPinned = favoriteBookmakerKeys.contains(b.key);
                        if (aPinned != bPinned) {
                          return aPinned ? -1 : 1;
                        }
                        return a.value.compareTo(b.value);
                      });
                final selectAllSelected =
                    favoriteBookmakerKeys.isEmpty ||
                    favoriteBookmakerKeys.length == sortedEntries.length;
                final chips = <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selectAllSelected,
                      label: const Text('Select All'),
                      selectedColor: QuantTheme.action.withValues(alpha: 0.3),
                      checkmarkColor: QuantTheme.textPrimary,
                      side: BorderSide(
                        color: selectAllSelected
                            ? QuantTheme.action
                            : QuantTheme.textMuted.withValues(alpha: 0.65),
                      ),
                      onSelected: (_) async {
                        await ref
                            .read(favoriteBookmakerKeysProvider.notifier)
                            .clearFavoriteBookmakerFilter();
                      },
                    ),
                  ),
                  ...sortedEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: favoriteBookmakerKeys.contains(entry.key),
                        selectedColor: QuantTheme.action.withValues(alpha: 0.3),
                        checkmarkColor: QuantTheme.textPrimary,
                        side: BorderSide(
                          color: favoriteBookmakerKeys.contains(entry.key)
                              ? QuantTheme.action
                              : QuantTheme.textMuted.withValues(alpha: 0.65),
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: QuantTheme.surface,
                              child: Text(
                                _bookmakerInitials(entry.value),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(entry.value),
                          ],
                        ),
                        onSelected: (_) async {
                          await ref
                              .read(favoriteBookmakerKeysProvider.notifier)
                              .toggleFavoriteBookmaker(entry.key);
                        },
                      ),
                    ),
                  ),
                ];
                return SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: chips,
                  ),
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
                child: Text('Failed to load sportsbooks: $error'),
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Expanded(
              child: opportunitiesAsync.when(
                data: (opportunities) {
                  if (opportunities.isEmpty) {
                    final hasBookFilter = favoriteBookmakerKeys.isNotEmpty;
                    return Center(
                      child: Text(
                        hasBookFilter
                            ? 'No opportunities match the selected sportsbook pair(s).'
                            : 'No arbitrage opportunities right now.',
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: opportunities.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 8,
                      thickness: 0.5,
                      color: Theme.of(context).dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final opportunity = opportunities[index];
                      final isFavorite = favoriteIds.contains(
                        opportunity.favoriteId,
                      );
                      return CyberOpportunityCard(
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

String _bookmakerInitials(String title) {
  final tokens = title
      .trim()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
  if (tokens.isEmpty) {
    return '?';
  }
  if (tokens.length == 1) {
    return tokens.first.substring(0, 1).toUpperCase();
  }
  return '${tokens[0][0]}${tokens[1][0]}'.toUpperCase();
}
