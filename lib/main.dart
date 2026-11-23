import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:verdant/data/app_data.dart';
import 'package:verdant/data/auth.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/l10n/i18n.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/services/notifications.dart';
import 'package:verdant/theme/theme.dart';

const _english = Locale('en', 'US');
const _italian = Locale('it', 'IT');

/// Restores saved data, then starts the app and the reminder notifications.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  usePathUrlStrategy();
  _registerFontLicenses();

  await Storage.init();
  restoreAppData();
  await authStore.init();

  runApp(const MyApp());
  // Scheduling can take a moment; do it after the first frame.
  NotificationService.init();
}

/// Adds the bundled font licences to the "About Verdant" licence page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [
      ('Inter', 'assets/fonts/Inter-OFL.txt'),
      ('Lora', 'assets/fonts/Lora-OFL.txt'),
    ]) {
      final text = await rootBundle.loadString(file);
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}

/// Root widget: theme, locale and routes. Rebuilds when the settings change (e.g. dark mode).
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// Applies a language change everywhere without leaving the current page.
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _shownLanguage = I18n.code;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appSettings.addListener(_refreshLanguage);
  }

  @override
  void dispose() {
    appSettings.removeListener(_refreshLanguage);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The phone's language changed while the app follows it.
  @override
  void didChangeLocales(List<Locale>? locales) {
    I18n.use(appSettings.language);
    _refreshLanguage();
  }

  void _refreshLanguage() {
    if (_shownLanguage == I18n.code) return;
    setState(() => _shownLanguage = I18n.code);
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Verdant.',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: appSettings.themeMode,
        locale: I18n.isItalian ? _italian : _english,
        supportedLocales: const [_english, _italian],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppRoutes.root,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        onUnknownRoute: AppRoutes.onUnknownRoute,
      ),
    );
  }
}
