import 'package:flutter/material.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/l10n/i18n.dart';

/// App preferences, saved on the device.
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.system;
  bool _push = true;
  bool _email = false;
  DateTime? _notificationsSeenAt;

  ThemeMode get themeMode => _themeMode;

  /// Belongs to this phone: it isn't synced and survives signing out.
  AppLanguage get language => _language;

  /// Phone notifications for care reminders.
  bool get push => _push;

  /// Email reminders, sent by the server when email is configured.
  bool get email => _email;

  /// Last time the user opened the notifications page.
  DateTime? get notificationsSeenAt => _notificationsSeenAt;

  set themeMode(ThemeMode value) => _set(() => _themeMode = value);
  set push(bool value) => _set(() => _push = value);
  set email(bool value) => _set(() => _email = value);

  set language(AppLanguage value) {
    _language = value;
    I18n.use(value);
    Storage.writeLocal(StorageKeys.language, value.name);
    notifyListeners();
  }

  void markNotificationsSeen([DateTime? at]) =>
      _set(() => _notificationsSeenAt = at ?? DateTime.now());

  void restore() {
    _language =
        AppLanguage.values.asNameMap()[Storage.read(StorageKeys.language)] ??
        AppLanguage.system;
    I18n.use(_language);
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
