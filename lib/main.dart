import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/i18n.dart';
import 'core/storage.dart';
import 'core/theme_controller.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

/// Temporary diagnostic scaffolding: the app has been crashing on launch on
/// a real device with no accessible logcat/crash report, so instead of
/// guessing blind, every error path below is made to show the real
/// exception + stack trace directly on screen (bright red, impossible to
/// miss) instead of Flutter's normal release-mode behavior of a blank grey
/// box or a silent app close. Remove this scaffolding once the real cause
/// is found and fixed.
void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  ErrorWidget.builder = (details) => _ErrorScreen(error: details.exception, stack: details.stack);

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    Object? startupError;
    StackTrace? startupStack;
    try {
      await Storage.init();
    } catch (e, st) {
      startupError = e;
      startupStack = st;
    }
    if (startupError != null) {
      runApp(_ErrorApp(error: startupError, stack: startupStack));
    } else {
      runApp(const NoorApp());
    }
  }, (error, stack) {
    runApp(_ErrorApp(error: error, stack: stack));
  });
}

class _ErrorApp extends StatelessWidget {
  final Object? error;
  final StackTrace? stack;
  const _ErrorApp({this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ErrorScreen(error: error, stack: stack),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object? error;
  final StackTrace? stack;
  const _ErrorScreen({this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB00020),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'NOOR — erreur au démarrage (écran de diagnostic temporaire)\n\n'
            '${error ?? "Erreur inconnue"}\n\n'
            '${stack ?? ""}',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
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
