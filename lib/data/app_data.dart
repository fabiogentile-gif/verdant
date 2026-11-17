import 'package:verdant/data/address.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/favorites.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/data/payment.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/data/storage.dart';

/// Loads everything saved on the device into the stores.
void restoreAppData() {
  appSettings.restore();
  plantCollection.restore();
  careSchedule.restore();
  cart.restore();
  wallet.restore();
  favorites.restore();
  orderHistory.restore();
  addressBook.restore();
}

/// Erases saved data and goes back to the demo content.
Future<void> resetAppData() async {
  await Storage.clearAll();
  appSettings.reset();
  plantCollection.reset();
  careSchedule.reset();
  cart.clear();
  wallet.reset();
  favorites.reset();
  orderHistory.reset();
  addressBook.reset();
}
