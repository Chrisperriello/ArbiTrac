import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calculator_screen.dart';
import 'dashboard_screen.dart';
import 'main_screen.dart';
import 'settings_screen.dart';
import '../providers/providers.dart';
import '../services/services.dart';

class MainLayoutShell extends ConsumerStatefulWidget {
  const MainLayoutShell({super.key});

  static const String routeName = '/command-center';

  @override
  ConsumerState<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends ConsumerState<MainLayoutShell> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final pages = const [DashboardScreen(), CalculatorScreen()];
    final usernameAsync = ref.watch(currentUserDisplayNameProvider);
    final topSafeInset = MediaQuery.paddingOf(context).top;
    final sidebarButtonTopOffset = topSafeInset + 8;

    return Scaffold(
      body: Row(
        children: [
          if (_isSidebarVisible)
            SizedBox(
              width: 72,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NavigationRail(
                      selectedIndex: _selectedIndex,
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -1,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.analytics_outlined),
                          selectedIcon: Icon(Icons.analytics),
                          label: Text('Feed'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.calculate_outlined),
                          selectedIcon: Icon(Icons.calculate),
                          label: Text('Calculator'),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Center(
                      child: IconButton(
                        tooltip: 'Account',
                        onPressed: () async {
                          final value = await _showSidebarAccountMenu(
                            context: context,
                            usernameAsync: usernameAsync,
                          );
                          if (!context.mounted || value == null) {
                            return;
                          }
                          if (value == 'settings') {
                            Navigator.of(context).pushNamed(
                              SettingsScreen.routeName,
                            );
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
                        icon: const Icon(Icons.account_circle_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isSidebarVisible)
            VerticalDivider(
              width: 1,
              thickness: 0.5,
              color: Theme.of(context).dividerColor,
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: pages[_selectedIndex]),
                Positioned(
                  top: sidebarButtonTopOffset,
                  left: 10,
                  child: IconButton.filledTonal(
                    tooltip: _isSidebarVisible ? 'Hide sidebar' : 'Show sidebar',
                    onPressed: () {
                      setState(() => _isSidebarVisible = !_isSidebarVisible);
                    },
                    icon: Icon(
                      _isSidebarVisible ? Icons.menu_open_outlined : Icons.menu,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _showSidebarAccountMenu({
  required BuildContext context,
  required AsyncValue<String> usernameAsync,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final username = usernameAsync.when(
        data: (value) => value,
        loading: () => 'User',
        error: (error, stackTrace) => 'User',
      );
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 68,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        dense: true,
                        title: Text(
                          username,
                          style: Theme.of(dialogContext).textTheme.titleMedium,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Settings'),
                        onTap: () =>
                            Navigator.of(dialogContext).pop<String>('settings'),
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.logout),
                        title: const Text('Sign out'),
                        onTap: () =>
                            Navigator.of(dialogContext).pop<String>('signout'),
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
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
