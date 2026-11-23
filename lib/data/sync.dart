import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:verdant/data/api_client.dart';
import 'package:verdant/data/app_data.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/data/storage.dart';

/// Keeps the signed-in user's stores in step with the server.
///
/// Every store saves through [Storage], so changes are picked up in one place.
/// Keys waiting to upload are saved too: edits made offline survive a restart
/// and are never overwritten by an older copy from the server.
class SyncService {
  static const _names = {
    StorageKeys.settings: 'settings',
    StorageKeys.plants: 'plants',
    StorageKeys.careSchedule: 'care_schedule',
    StorageKeys.cart: 'cart',
    StorageKeys.wallet: 'wallet',
    StorageKeys.favorites: 'favorites',
    StorageKeys.address: 'address',
  };

  final Set<String> _dirty = {};
  Timer? _timer;
  Future<void>? _running;
  int _session = 0;

  void start() {
    _session++;
    _dirty
      ..clear()
      ..addAll(
        (Storage.read(StorageKeys.syncDirty) as List? ?? const [])
            .whereType<String>()
            .where(_names.containsKey),
      );
    Storage.onWrite = _onWrite;
    if (_dirty.isNotEmpty) _schedule(const Duration(seconds: 1));
  }

  void stop() {
    _session++;
    Storage.onWrite = null;
    _timer?.cancel();
    _timer = null;
    _dirty.clear();
  }

  void _onWrite(String key) {
    if (!_names.containsKey(key)) return;
    _dirty.add(key);
    _saveDirty();
    _schedule(const Duration(milliseconds: 800));
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(flush()));
  }

  void _saveDirty() =>
      Storage.writeLocal(StorageKeys.syncDirty, _dirty.toList());

  /// Uploads everything that changed.
  Future<void> flush() => _running ??= _drain().whenComplete(() {
    _running = null;
  });

  Future<void> _drain() async {
    final session = _session;
    while (_dirty.isNotEmpty && session == _session) {
      final key = _dirty.first;
      _dirty.remove(key);
      try {
        await api.put('/sync/${_names[key]}', {'value': Storage.read(key)});
        if (session == _session) _saveDirty();
      } on ApiException catch (e) {
        if (session != _session) return;
        if (e.isNetwork || (e.status ?? 500) >= 500) {
          _dirty.add(key);
          _schedule(const Duration(seconds: 30));
          return;
        }
        // The server refused this data: retrying would fail forever.
        debugPrint('Sync rejected for $key: $e');
        _saveDirty();
      }
    }
  }

  /// Downloads the account's data and reloads the stores.
  ///
  /// With [adoptLocal] (right after signing in) anything the server doesn't
  /// have yet is uploaded from this phone. Otherwise the server is the
  /// reference, so data erased on another device goes away here too.
  Future<void> pull({bool adoptLocal = false}) async {
    final session = _session;
    await flush();
    final data = await api.get('/sync');
    if (session != _session || data is! Map) return;

    final stores = data['stores'] is Map ? data['stores'] as Map : const {};
    for (final MapEntry(key: key, value: name) in _names.entries) {
      if (_dirty.contains(key)) continue;
      if (stores.containsKey(name)) {
        Storage.writeLocal(key, stores[name]);
      } else if (adoptLocal) {
        if (Storage.read(key) != null) _dirty.add(key);
      } else {
        Storage.remove(key);
      }
    }
    _saveDirty();
    reloadAppData();
    orderHistory.mergeFromServer(data['orders'] as List? ?? const []);
    if (_dirty.isNotEmpty) _schedule(const Duration(milliseconds: 200));
  }

  /// Deletes the account's data on the server ("Erase my data").
  Future<void> eraseRemote() async {
    _timer?.cancel();
    await _running;
    await api.delete('/sync');
    _dirty.clear();
    _saveDirty();
  }
}

final syncService = SyncService();
