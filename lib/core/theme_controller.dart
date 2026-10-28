import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'storage.dart';

/// Theme mode choice, mirroring the web app's data-theme attribute:
/// "system" follows the OS (the default), or the user pins light/dark.
enum AppThemeMode { system, light, dark }

/// Persisted theme-mode + accent choice, exactly like [AppLocale] does for
/// language. Lives above [MaterialApp] so every screen rebuilds on change.
class AppThemeController extends ChangeNotifier {
  AppThemeMode _mode = _modeFromString(Storage.get<String>('theme-mode', 'system'));
  AppAccent _accent = _accentFromString(Storage.get<String>('accent', 'default'));

  AppThemeMode get mode => _mode;
  AppAccent get accent => _accent;

  ThemeMode get flutterThemeMode => switch (_mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    await Storage.set('theme-mode', mode.name);
    notifyListeners();
  }

  Future<void> setAccent(AppAccent accent) async {
    if (accent == _accent) return;
    _accent = accent;
    await Storage.set('accent', accent == AppAccent.defaultTeal ? 'default' : accent.name);
    notifyListeners();
  }

  static AppThemeMode _modeFromString(String s) => switch (s) {
        'light' => AppThemeMode.light,
        'dark' => AppThemeMode.dark,
        _ => AppThemeMode.system,
      };

  static AppAccent _accentFromString(String s) => switch (s) {
        'indigo' => AppAccent.indigo,
        'bordeaux' => AppAccent.bordeaux,
        _ => AppAccent.defaultTeal,
      };
}

/// Makes the single app-wide [AppThemeController] reachable from any screen
/// via `AppThemeScope.of(context)`, same pattern as [AppLocaleScope].
class AppThemeScope extends InheritedNotifier<AppThemeController> {
  const AppThemeScope({Key? key, required AppThemeController controller, required Widget child})
      : super(key: key, notifier: controller, child: child);

  static AppThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found in context');
    return scope!.notifier!;
  }
}
