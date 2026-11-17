import 'package:flutter/material.dart';
import 'package:verdant/data/storage.dart';

/// App preferences, saved on the device.
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _push = true;
  bool _email = false;
  DateTime? _notificationsSeenAt;

  ThemeMode get themeMode => _themeMode;

  /// Phone notifications for care reminders.
  bool get push => _push;

  /// Email reminders (preference only until the backend can send email).
  bool get email => _email;

  /// Last time the user opened the notifications page.
  DateTime? get notificationsSeenAt => _notificationsSeenAt;

  set themeMode(ThemeMode value) => _set(() => _themeMode = value);
  set push(bool value) => _set(() => _push = value);
  set email(bool value) => _set(() => _email = value);

  void markNotificationsSeen([DateTime? at]) =>
      _set(() => _notificationsSeenAt = at ?? DateTime.now());

  void restore() {
    final json = Storage.read(StorageKeys.settings);
    if (json is! Map) return;
    _themeMode = ThemeMode.values.asNameMap()[json['themeMode']] ?? _themeMode;
    _push = json['push'] as bool? ?? _push;
    _email = json['email'] as bool? ?? _email;
    final seen = json['notificationsSeenAt'] as String?;
    _notificationsSeenAt = seen == null ? null : DateTime.tryParse(seen);
    notifyListeners();
  }

  void reset() {
    _themeMode = ThemeMode.system;
    _push = true;
    _email = false;
    _notificationsSeenAt = null;
    notifyListeners();
  }

  void _set(VoidCallback change) {
    change();
    Storage.write(StorageKeys.settings, {
      'themeMode': _themeMode.name,
      'push': _push,
      'email': _email,
      'notificationsSeenAt': _notificationsSeenAt?.toIso8601String(),
    });
    notifyListeners();
  }
}

/// App preferences shared by every page.
final appSettings = AppSettings();
