import 'package:verdant/data/address.dart';
import 'package:verdant/data/auth.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/favorites.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/data/payment.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/data/sync.dart';

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

/// Puts every store back to its starting content, without saving.
void resetStores() {
  appSettings.reset();
  plantCollection.reset();
  careSchedule.reset();
  cart.reset();
  wallet.reset();
  favorites.reset();
  orderHistory.reset();
  addressBook.reset();
}

/// Reloads the stores from what is saved (e.g. after a sync).
void reloadAppData() {
  resetStores();
  restoreAppData();
}

/// Erases the account's data on the server and on this phone.
/// Throws `ApiException` if the server can't be reached: nothing is erased.
Future<void> resetAppData() async {
  await syncService.eraseRemote();
  await Storage.clearAll();
  authStore.rememberUser();
  resetStores();
}
