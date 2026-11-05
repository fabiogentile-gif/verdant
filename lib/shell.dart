import 'package:flutter/material.dart';
import 'package:verdant/router/router.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _navKey = GlobalKey<NavigatorState>();
  int _index = 0;

  static const _tabs = [
    AppRoutes.homepage,
    AppRoutes.plants,
    AppRoutes.profile,
    AppRoutes.activity,
    AppRoutes.greenhouse,
  ];

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _navKey.currentState!.pushReplacementNamed(_tabs[i]);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Navigator(
        key: _navKey,
        initialRoute: AppRoutes.homepage,
        onGenerateRoute: AppRoutes.onGenerateTab,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_outlined),
            selectedIcon: Icon(Icons.star),
            label: 'Preferiti',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}
