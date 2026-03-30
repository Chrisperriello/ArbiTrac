import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkModeAsync = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
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
      ),
    );
  }
}
