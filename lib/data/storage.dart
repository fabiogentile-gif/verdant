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

  /// Called after each store save, so changes can be uploaded.
  static void Function(String key)? onWrite;

  static void write(String key, Object? value) {
    writeLocal(key, value);
    onWrite?.call(key);
  }

  /// Saves without reporting a change (data that came from the server).
  static void writeLocal(String key, Object? value) {
    _prefs?.setString(key, jsonEncode(value));
  }

  static void remove(String key) {
    _prefs?.remove(key);
  }

  /// Removes everything Verdant saved on this device, except its language.
  static Future<void> clearAll() async {
    final language = _prefs?.getString(StorageKeys.language);
    await _prefs?.clear();
    if (language != null) {
      await _prefs?.setString(StorageKeys.language, language);
    }
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
  static const user = 'user.v1';
  static const syncDirty = 'sync_dirty.v1';
  static const language = 'language.v1';
}
