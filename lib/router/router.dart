import 'package:flutter/material.dart';
import 'package:verdant/pages/activity.dart';
import 'package:verdant/pages/greenhouse.dart';
import 'package:verdant/pages/homepage.dart';
import 'package:verdant/pages/plants.dart';
import 'package:verdant/pages/profile.dart';
import 'package:verdant/shell.dart';

class AppRoutes {
  static const root = '/';
  static const homepage = '/homepage';
  static const profile = '/profile';
  static const plants = '/plants';
  static const greenhouse = '/greenhouse';
  static const activity = '/activity';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AppShell(),
        );
    }
    return null;
  }

  static Route<dynamic>? onGenerateTab(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case profile:
        page = Profile();
      case plants:
        page = Plants();
      case greenhouse:
        page = Greenhouse();
      case activity:
        page = Activity();
      case homepage:
      default:
        page = Homepage();
    }
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}
