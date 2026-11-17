import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/intl.dart';
import 'package:verdant/data/app_data.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/services/notifications.dart';
import 'package:verdant/theme/theme.dart';

/// The app is written in English; dates and pickers follow the same locale.
const appLocale = Locale('en', 'US');

/// Restores saved data, then starts the app and the reminder notifications.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'en_US';
  usePathUrlStrategy();
  _registerFontLicenses();

  await Storage.init();
  restoreAppData();

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
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        locale: appLocale,
        supportedLocales: const [appLocale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppRoutes.root,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        onUnknownRoute: AppRoutes.onUnknownRoute,
      ),
    );
  }
}
