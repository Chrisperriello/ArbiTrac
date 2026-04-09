
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _SettingsAppBar(),
        body: TabBarView(
          children: [_FavoritesSettingsTab(), _ThemeSettingsTab()],
        ),
      ),
    );
  }
}

class _SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SettingsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Settings'),
      bottom: const TabBar(
        tabs: [
          Tab(text: 'Favorites', icon: Icon(Icons.star_outline)),
          Tab(text: 'Theme', icon: Icon(Icons.palette_outlined)),
        ],
      ),
    );
  }
}

class _FavoritesSettingsTab extends ConsumerWidget {
  const _FavoritesSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteSportKeysAsync = ref.watch(favoriteSportKeysProvider);
    final sportsByKeyAsync = ref.watch(availableSportsByKeyProvider);
    final favoriteBookmakerKeysAsync = ref.watch(favoriteBookmakerKeysProvider);
    final bookmakersByKeyAsync = ref.watch(availableBookmakersByKeyProvider);

    final favoriteSportKeys =
        favoriteSportKeysAsync.asData?.value ?? const <String>{};
    final favoriteBookmakerKeys =
        favoriteBookmakerKeysAsync.asData?.value ?? const <String>{};
    final sportsByKey = sportsByKeyAsync.asData?.value ?? const <String, String>{};
    final bookmakersByKey =
        bookmakersByKeyAsync.asData?.value ?? const <String, String>{};
    final favoriteSportItems = _itemsFromKeys(
      keys: favoriteSportKeys,
      labelsByKey: sportsByKey,
    );
    final favoriteBookItems = _itemsFromKeys(
      keys: favoriteBookmakerKeys,
      labelsByKey: bookmakersByKey,
    );
    final allSportItems = _itemsFromMap(sportsByKey);
    final allBookItems = _itemsFromMap(bookmakersByKey);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FavoritesSection(
            title: 'Favorite Sports',
            addTooltip: 'Add favorite sport',
            onAddPressed: () {
              _showAddFavoriteModal(
                context: context,
                title: 'Add favorite sport',
                loading:
                    favoriteSportKeysAsync.isLoading || sportsByKeyAsync.isLoading,
                hasError:
                    favoriteSportKeysAsync.hasError || sportsByKeyAsync.hasError,
                items: allSportItems,
                selectedKeys: favoriteSportKeys,
                onAddPressed: (item) async {
                  await ref
                      .read(favoriteSportKeysProvider.notifier)
                      .toggleFavoriteSport(item.key);
                },
              );
            },
            items: favoriteSportItems,
            onRemovePressed: (item) async {
              await ref
                  .read(favoriteSportKeysProvider.notifier)
                  .toggleFavoriteSport(item.key);
            },
            loading:
                favoriteSportKeysAsync.isLoading || sportsByKeyAsync.isLoading,
            error:
                favoriteSportKeysAsync.hasError || sportsByKeyAsync.hasError,
          ),
          const SizedBox(height: 16),
          _FavoritesSection(
            title: 'Favorite Books',
            addTooltip: 'Add favorite sportsbook',
            onAddPressed: () {
              _showAddFavoriteModal(
                context: context,
                title: 'Add favorite sportsbook',
                loading:
                    favoriteBookmakerKeysAsync.isLoading ||
                    bookmakersByKeyAsync.isLoading,
                hasError:
                    favoriteBookmakerKeysAsync.hasError ||
                    bookmakersByKeyAsync.hasError,
                items: allBookItems,
                selectedKeys: favoriteBookmakerKeys,
                onAddPressed: (item) async {
                  await ref
                      .read(favoriteBookmakerKeysProvider.notifier)
                      .toggleFavoriteBookmaker(item.key);
                },
              );
            },
            items: favoriteBookItems,
            onRemovePressed: (item) async {
              await ref
                  .read(favoriteBookmakerKeysProvider.notifier)
                  .toggleFavoriteBookmaker(item.key);
            },
            loading:
                favoriteBookmakerKeysAsync.isLoading ||
                bookmakersByKeyAsync.isLoading,
            error:
                favoriteBookmakerKeysAsync.hasError ||
                bookmakersByKeyAsync.hasError,
          ),
        ],
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({
    required this.title,
    required this.addTooltip,
    required this.onAddPressed,
    required this.items,
    required this.onRemovePressed,
    required this.loading,
    required this.error,
  });

  final String title;
  final String addTooltip;
  final VoidCallback onAddPressed;
  final List<_FavoriteEntityItem> items;
  final Future<void> Function(_FavoriteEntityItem item) onRemovePressed;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: addTooltip,
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Failed to load items.'),
              )
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No favorites selected yet.'),
              )
            else
              ...items.map(
                (item) => _SettingFavoriteCard(
                  item: item,
                  onRemovePressed: () async {
                    await onRemovePressed(item);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSettingsTab extends ConsumerWidget {
  const _ThemeSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkModeAsync = ref.watch(appThemeModeProvider);
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Dark mode'),
          subtitle: const Text('Save theme preference on this device'),
          value: isDarkModeAsync.asData?.value ?? false,
          onChanged: isDarkModeAsync.isLoading
              ? null
              : (enabled) async {
                  await ref
                      .read(appThemeModeProvider.notifier)
                      .setDarkMode(enabled);
                },
        ),
      ],
    );
  }
}

class _SettingFavoriteCard extends StatelessWidget {
  const _SettingFavoriteCard({
    required this.item,
    required this.onRemovePressed,
  });

  final _FavoriteEntityItem item;
  final Future<void> Function() onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        title: Text(item.label),
        trailing: IconButton(
          tooltip: 'Remove',
          onPressed: onRemovePressed,
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ),
    );
  }
}

class _FavoriteEntityItem {
  const _FavoriteEntityItem({required this.key, required this.label});

  final String key;
  final String label;
}

List<_FavoriteEntityItem> _itemsFromKeys({
  required Set<String> keys,
  required Map<String, String> labelsByKey,
}) {
  final items = keys
      .map((key) => _FavoriteEntityItem(key: key, label: labelsByKey[key] ?? key))
      .where((item) => item.label.trim().isNotEmpty)
      .toList(growable: false);
  items.sort((a, b) => a.label.compareTo(b.label));
  return items;
}

List<_FavoriteEntityItem> _itemsFromMap(Map<String, String> labelsByKey) {
  final items = labelsByKey.entries
      .where((entry) => entry.key.trim().isNotEmpty)
      .map((entry) => _FavoriteEntityItem(key: entry.key, label: entry.value))
      .toList(growable: false);
  items.sort((a, b) => a.label.compareTo(b.label));
  return items;
}

Future<void> _showAddFavoriteModal({
  required BuildContext context,
  required String title,
  required bool loading,
  required bool hasError,
  required List<_FavoriteEntityItem> items,
  required Set<String> selectedKeys,
  required Future<void> Function(_FavoriteEntityItem item) onAddPressed,
}) async {
  final selected = Set<String>.from(selectedKeys);
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: const SizedBox.expand(),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: loading
                                ? const Center(child: CircularProgressIndicator())
                                : hasError
                                ? const Center(
                                    child: Text(
                                      'Could not load available items right now.',
                                    ),
                                  )
                                : items.isEmpty
                                ? const Center(
                                    child: Text('No items available to add yet.'),
                                  )
                                : ListView.separated(
                                    itemCount: items.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      final alreadySelected = selected.contains(
                                        item.key,
                                      );
                                      return Card(
                                        elevation: 0,
                                        margin: EdgeInsets.zero,
                                        child: ListTile(
                                          title: Text(item.label),
                                          trailing: IconButton(
                                            tooltip: alreadySelected
                                                ? 'Already added'
                                                : 'Add',
                                            onPressed: alreadySelected
                                                ? null
                                                : () async {
                                                    await onAddPressed(item);
                                                    setModalState(() {
                                                      selected.add(item.key);
                                                    });
                                                  },
                                            icon: Icon(
                                              alreadySelected
                                                  ? Icons.check_circle
                                                  : Icons.add_circle_outline,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
