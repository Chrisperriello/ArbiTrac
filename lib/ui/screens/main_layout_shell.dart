import 'package:flutter/material.dart';

import '../../screens/dashboard_screen.dart';
import 'calculator_screen.dart';

class MainLayoutShell extends StatefulWidget {
  const MainLayoutShell({super.key});

  static const String routeName = '/command-center';

  @override
  State<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends State<MainLayoutShell> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final pages = const [DashboardScreen(), CalculatorScreen()];

    return Scaffold(
      body: Row(
        children: [
          if (_isSidebarVisible)
            NavigationRail(
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
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
                  top: 10,
                  left: 10,
                  child: IconButton.filledTonal(
                    tooltip: _isSidebarVisible
                        ? 'Hide sidebar'
                        : 'Show sidebar',
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
