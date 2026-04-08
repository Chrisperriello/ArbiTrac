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

    final favoriteSportLabels = _labelsFromKeys(
      keys: favoriteSportKeysAsync.asData?.value ?? const <String>{},
      labelsByKey: sportsByKeyAsync.asData?.value ?? const <String, String>{},
    );
    final favoriteBookLabels = _labelsFromKeys(
      keys: favoriteBookmakerKeysAsync.asData?.value ?? const <String>{},
      labelsByKey:
          bookmakersByKeyAsync.asData?.value ?? const <String, String>{},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FavoritesSection(
            title: 'Favorite Sports',
            addTooltip: 'Add favorite sport',
            onAddPressed: () => _showStepNotice(context, 'sport'),
            items: favoriteSportLabels,
            loading:
                favoriteSportKeysAsync.isLoading || sportsByKeyAsync.isLoading,
            error:
                favoriteSportKeysAsync.hasError || sportsByKeyAsync.hasError,
          ),
          const SizedBox(height: 16),
          _FavoritesSection(
            title: 'Favorite Books',
            addTooltip: 'Add favorite sportsbook',
            onAddPressed: () => _showStepNotice(context, 'sportsbook'),
            items: favoriteBookLabels,
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
    required this.loading,
    required this.error,
  });

  final String title;
  final String addTooltip;
  final VoidCallback onAddPressed;
  final List<String> items;
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
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item),
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

List<String> _labelsFromKeys({
  required Set<String> keys,
  required Map<String, String> labelsByKey,
}) {
  final labels = keys
      .map((key) => labelsByKey[key] ?? key)
      .where((label) => label.trim().isNotEmpty)
      .toList(growable: false);
  labels.sort();
  return labels;
}

void _showStepNotice(BuildContext context, String typeLabel) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Add-$typeLabel flow is next (Step 5.2.1.2).',
      ),
    ),
  );
}
