import 'package:flutter/material.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/widgets/components/app_bottom_navigation.dart';

/// Main layout: the tab pages in a nested navigator and the bottom navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Lets pages pushed on the root navigator (e.g. the cart) switch tabs.
  static final globalKey = GlobalKey<AppShellState>();

  static AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

/// State of [AppShell]: the selected tab and the nested navigator.
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
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: Navigator(
          key: _navKey,
          initialRoute: AppRoutes.homepage,
          onGenerateRoute: AppRoutes.onGenerateTab,
        ),
      ),
      floatingActionButton: AppCenterButton(
        selected: _index == AppBottomNavigation.featuredIndex,
        onPressed: () => _onTap(AppBottomNavigation.featuredIndex),
      ),
      floatingActionButtonLocation: const _FixedCenterDocked(),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _index,
        onTap: _onTap,
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
    );
  }
}

/// Keeps the centre button docked on the bottom bar even when a snackbar
/// or the keyboard is shown (the default location would move it up).
class _FixedCenterDocked extends FloatingActionButtonLocation {
  const _FixedCenterDocked();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry g) {
    final x = (g.scaffoldSize.width - g.floatingActionButtonSize.width) / 2;
    // contentBottom = top edge of the bottom bar, not affected by
    // snackbars or the keyboard.
    final y = g.contentBottom - g.floatingActionButtonSize.height / 2;
    return Offset(x, y);
  }
}
