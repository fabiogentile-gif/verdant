import 'package:flutter/material.dart';
import 'package:verdant/pages/activity.dart';
import 'package:verdant/pages/cart.dart';
import 'package:verdant/pages/checkout.dart';
import 'package:verdant/pages/greenhouse.dart';
import 'package:verdant/pages/homepage.dart';
import 'package:verdant/pages/plants.dart';
import 'package:verdant/pages/product_details.dart';
import 'package:verdant/pages/profile.dart';
import 'package:verdant/shell.dart';

class AppRoutes {
  static const root = '/';
  static const homepage = '/homepage';
  static const profile = '/profile';
  static const plants = '/plants';
  static const greenhouse = '/greenhouse';
  static const activity = '/activity';
  static const productDetails = '/product';
  static const cart = '/cart';
  static const checkout = '/checkout';

  static String productPath(int id) => '$productDetails/$id';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? root);

    if (uri.pathSegments.length == 2 &&
        '/${uri.pathSegments.first}' == productDetails) {
      final id = int.tryParse(uri.pathSegments[1]);
      if (id != null) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProductDetailsPage(productId: id),
        );
      }
    }

    switch (settings.name) {
      case root:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AppShell(key: AppShell.globalKey),
        );
      case cart:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CartPage(),
        );
      case checkout:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CheckoutPage(),
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
      pageBuilder: (_, _, _) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}
