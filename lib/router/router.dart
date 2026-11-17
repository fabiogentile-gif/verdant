import 'package:flutter/material.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/pages/activity.dart';
import 'package:verdant/pages/cart.dart';
import 'package:verdant/pages/checkout.dart';
import 'package:verdant/pages/greenhouse.dart';
import 'package:verdant/pages/homepage.dart';
import 'package:verdant/pages/not_found.dart';
import 'package:verdant/pages/notifications.dart';
import 'package:verdant/pages/personal_plant_details.dart';
import 'package:verdant/pages/plants.dart';
import 'package:verdant/pages/product_details.dart';
import 'package:verdant/pages/profile.dart';
import 'package:verdant/pages/profile/addresses.dart';
import 'package:verdant/pages/profile/care_reminders.dart';
import 'package:verdant/pages/profile/help.dart';
import 'package:verdant/pages/profile/orders.dart';
import 'package:verdant/pages/profile/payment_methods.dart';
import 'package:verdant/pages/profile/privacy.dart';
import 'package:verdant/shell.dart';

class AppRoutes {
  // Tabs (inside the shell's nested navigator).
  static const homepage = '/homepage';
  static const profile = '/profile';
  static const plants = '/plants';
  static const greenhouse = '/greenhouse';
  static const activity = '/activity';

  // Root routes (pushed above the shell).
  static const root = '/';
  static const productDetails = '/product';
  static const plantDetails = '/plant';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const notifications = '/notifications';
  static const orders = '/orders';
  static const addresses = '/addresses';
  static const paymentMethods = '/payment-methods';
  static const careReminders = '/care-reminders';
  static const help = '/help';
  static const privacy = '/privacy';

  static String productPath(int id) => '$productDetails/$id';
  static String plantPath(String id) => '$plantDetails/$id';
  static String orderPath(String number) => '$orders/$number';

  static final Map<String, WidgetBuilder> _pages = {
    root: (_) => AppShell(key: AppShell.globalKey),
    cart: (_) => const CartPage(),
    checkout: (_) => const CheckoutPage(),
    notifications: (_) => const NotificationsPage(),
    orders: (_) => const OrdersPage(),
    addresses: (_) => const AddressPage(),
    paymentMethods: (_) => const PaymentMethodsPage(),
    careReminders: (_) => const CareRemindersPage(),
    help: (_) => const HelpPage(),
    privacy: (_) => const PrivacyPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? root);
    MaterialPageRoute<dynamic> page(WidgetBuilder builder) =>
        MaterialPageRoute(settings: settings, builder: builder);

    if (uri.pathSegments.length == 2) {
      final first = '/${uri.pathSegments.first}';
      final id = uri.pathSegments[1];
      if (first == productDetails) {
        final productId = int.tryParse(id);
        if (productId != null) {
          return page((_) => ProductDetailsPage(productId: productId));
        }
      }
      if (first == plantDetails) {
        return page((_) => PersonalPlantDetails(plantId: id));
      }
      if (first == orders) {
        return page((_) => OrderDetailsPage(number: id));
      }
    }

    final builder = _pages[uri.path.isEmpty ? root : uri.path];
    return builder == null ? null : page(builder);
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      MaterialPageRoute(
        settings: settings,
        builder: (_) => const NotFoundPage(),
      );

  static Route<dynamic>? onGenerateTab(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case profile:
        page = const Profile();
      case plants:
        page = const Plants();
      case greenhouse:
        page = const Greenhouse();
      case activity:
        page = const Activity();
      case homepage:
      default:
        page = const Homepage();
    }
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

/// Pushes a root route (above the tabs) from anywhere.
Future<T?> pushRoot<T>(BuildContext context, String route) =>
    Navigator.of(context, rootNavigator: true).pushNamed<T>(route);

/// Opens the details of one of the user's plants.
void openPlant(BuildContext context, OwnedPlant plant) =>
    pushRoot(context, AppRoutes.plantPath(plant.id));

/// Switches the bottom navigation to [tab] (e.g. [AppRoutes.greenhouse]),
/// closing any page pushed above the shell.
void goToTab(BuildContext context, String tab) {
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  AppShell.globalKey.currentState?.goTotab(tab);
}
