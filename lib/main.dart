import 'package:flutter/material.dart';
import 'core/i18n.dart';
import 'core/storage.dart';
import 'core/theme_controller.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  runApp(const NoorApp());
}

class NoorApp extends StatefulWidget {
  const NoorApp({super.key});

  @override
  State<NoorApp> createState() => _NoorAppState();
}

class _NoorAppState extends State<NoorApp> {
  final AppLocale _locale = AppLocale();
  final AppThemeController _themeCtrl = AppThemeController();

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      locale: _locale,
      child: AppThemeScope(
        controller: _themeCtrl,
        child: ListenableBuilder(
          listenable: Listenable.merge([_locale, _themeCtrl]),
          builder: (context, _) {
            final lightPalette = AppPalette.resolve(Brightness.light, _themeCtrl.accent);
            final darkPalette = AppPalette.resolve(Brightness.dark, _themeCtrl.accent);
            return MaterialApp(
              title: 'Noor',
              debugShowCheckedModeBanner: false,
              themeMode: _themeCtrl.flutterThemeMode,
              theme: buildAppTheme(lightPalette, Brightness.light),
              darkTheme: buildAppTheme(darkPalette, Brightness.dark),
              home: const HomeShell(),
            );
          },
        ),
      ),
    );
  }
}
