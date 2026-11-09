import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:verdant/router/router.dart';
import 'package:verdant/theme/theme.dart';
import 'package:verdant/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        debugShowCheckedModeBanner: true, //da togliere dopo

        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,  
        initialRoute: AppRoutes.root,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        title: 'Verdant.',
      ),
    );
  }
}
