import 'dart:ui' show PlatformDispatcher;

import 'package:intl/intl.dart';
import 'package:verdant/l10n/it.dart';

/// Language choice saved in the settings.
enum AppLanguage { system, en, it }

/// The language the app is showing right now.
///
/// English text is the key: `'Sign in'.tr` looks it up in the Italian
/// dictionary ([italian]) and falls back to English when it is missing.
abstract final class I18n {
  static String _code = 'en';

  static String get code => _code;
  static bool get isItalian => _code == 'it';

  /// `it_IT` or `en_US`, for dates.
  static String get intlLocale => isItalian ? 'it_IT' : 'en_US';

  /// Applies [language]; `system` follows the phone's language.
  static void use(AppLanguage language) {
    _code = switch (language) {
      AppLanguage.it => 'it',
      AppLanguage.en => 'en',
      AppLanguage.system =>
        PlatformDispatcher.instance.locale.languageCode == 'it' ? 'it' : 'en',
    };
    Intl.defaultLocale = intlLocale;
  }

  static final Map<String, String> _reverse = () {
    final reverse = <String, String>{};
    for (final e in italian.entries) {
      reverse.putIfAbsent(e.value, () => e.key);
    }
    return reverse;
  }();

  /// English key of a translated value, to save text that must stay
  /// language-neutral (e.g. a room picked from the suggestions).
  static String source(String text) => _reverse[text] ?? text;

  /// Like [source], but only when the English text is one of [allowed], so
  /// a name the user typed is never swapped for an unrelated translation.
  static String sourceIn(String text, Set<String> allowed) {
    final key = source(text);
    return allowed.contains(key) ? key : text;
  }

  static final _onlyLeft = RegExp(r'^Only (\d+) left of (.+)\.$');

  /// Translates a message written by the server.
  static String server(String message) {
    if (!isItalian) return message;
    final m = _onlyLeft.firstMatch(message);
    if (m != null) return 'Disponibili solo ${m[1]} di ${m[2]!.tr}.';
    return message.tr;
  }
}

extension Translate on String {
  /// This text in the current language.
  String get tr => I18n.isItalian ? (italian[this] ?? this) : this;
}

/// Translates [template] and fills `{0}`, `{1}`… with [args].
String trArgs(String template, List<Object?> args) {
  var text = template.tr;
  for (var i = 0; i < args.length; i++) {
    text = text.replaceAll('{$i}', '${args[i]}');
  }
  return text;
}

const _italianPatterns = {
  'EEE, MMM d': 'EEE d MMM',
  'h:mm a': 'HH:mm',
  'MMM d, y': 'd MMM y',
  'MMMM d, y': 'd MMMM y',
  'EEE, MMMM d, y': 'EEE d MMMM y',
  'MMM d': 'd MMM',
  'MMM d · h:mm a': 'd MMM · HH:mm',
  'EEEE, MMMM d': 'EEEE d MMMM',
};

/// A date format for the current language, from its US English pattern.
DateFormat appDate(String pattern) => DateFormat(
  I18n.isItalian ? (_italianPatterns[pattern] ?? pattern) : pattern,
  I18n.intlLocale,
);

/// "Nov 10–12" / "10–12 nov", across months when needed.
String formatDateRange(DateTime start, DateTime end) {
  final short = appDate('MMM d');
  if (start.month != end.month || start.year != end.year) {
    return '${short.format(start)} – ${short.format(end)}';
  }
  final month = DateFormat('MMM', I18n.intlLocale).format(start);
  return I18n.isItalian
      ? '${start.day}–${end.day} $month'
      : '$month ${start.day}–${end.day}';
}
