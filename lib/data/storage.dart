import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tiny JSON key-value store on top of shared_preferences.
///
/// Before [init] (e.g. in widget tests) reads return null and writes are
/// ignored, so every store simply works in memory.
abstract final class Storage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Object? read(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static void write(String key, Object? value) {
    _prefs?.setString(key, jsonEncode(value));
  }

  /// Removes everything Verdant saved on this device.
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}

/// Keys used by the stores, in one place.
abstract final class StorageKeys {
  static const settings = 'settings.v1';
  static const plants = 'plants.v1';
  static const careSchedule = 'care_schedule.v1';
  static const cart = 'cart.v1';
  static const wallet = 'wallet.v1';
  static const favorites = 'favorites.v1';
  static const orders = 'orders.v1';
  static const address = 'address.v1';
}
