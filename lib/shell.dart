import 'package:flutter/material.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/widgets/components/app_bottom_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Lets pages pushed on the root navigator (e.g. the cart) switch tabs.
  static final globalKey = GlobalKey<AppShellState>();

  static AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  final _navKey = GlobalKey<NavigatorState>();
  int _index = 0;

  static const _tabs = [
    AppRoutes.homepage,
    AppRoutes.plants,
    AppRoutes.greenhouse,
    AppRoutes.activity,
    AppRoutes.profile,
  ];

  void goTotab(String route) {
    final i = _tabs.indexOf(route);
    if (i != -1) _onTap(i);
  }

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
      floatingActionButton: AppCenterButton(
        selected: _index == AppBottomNavigation.featuredIndex,
        onPressed: () => _onTap(AppBottomNavigation.featuredIndex),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _index,
        onTap: _onTap,
      ),
    );
  }
}
