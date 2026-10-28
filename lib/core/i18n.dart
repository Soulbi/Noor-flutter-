import 'package:flutter/material.dart';
import 'storage.dart';

enum AppLang { fr, en }

/// Translation strings. Phase 1 only needs the navigation shell's own
/// labels — each later phase (Prières, Jeûne, Coran, Paramètres) adds its
/// own keys here as that screen is ported, mirroring the single i18n
/// dictionary already used in the web app.
const Map<String, Map<AppLang, String>> _strings = {
  'appName': {AppLang.fr: 'Noor', AppLang.en: 'Noor'},
  'navAccueil': {AppLang.fr: 'Accueil', AppLang.en: 'Home'},
  'navJeune': {AppLang.fr: 'Jeûne', AppLang.en: 'Fasting'},
  'navPrieres': {AppLang.fr: 'Prières', AppLang.en: 'Prayers'},
  'navCoran': {AppLang.fr: 'Coran', AppLang.en: 'Quran'},
  'navParametres': {AppLang.fr: 'Réglages', AppLang.en: 'Settings'},
  'comingSoon': {
    AppLang.fr: 'Ce module arrive dans une prochaine étape.',
    AppLang.en: 'This module is coming in a future step.',
  },
};

/// App-wide current language, persisted like every other setting. Screens
/// listen via [AnimatedBuilder]/[ListenableBuilder] on this notifier (or
/// read it through [AppLocaleScope.of]) so switching language updates the
/// whole UI immediately, same as the web app's currentLang + re-render.
class AppLocale extends ChangeNotifier {
  AppLang _lang = Storage.get<String>('lang', 'fr') == 'en' ? AppLang.en : AppLang.fr;

  AppLang get lang => _lang;

  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[_lang] ?? entry[AppLang.fr] ?? key;
  }

  Future<void> setLang(AppLang lang) async {
    if (lang == _lang) return;
    _lang = lang;
    await Storage.set('lang', lang == AppLang.en ? 'en' : 'fr');
    notifyListeners();
  }
}

/// Makes the single app-wide [AppLocale] instance reachable from any screen
/// via `AppLocaleScope.of(context)`.
class AppLocaleScope extends InheritedNotifier<AppLocale> {
  const AppLocaleScope({Key? key, required AppLocale locale, required Widget child})
      : super(key: key, notifier: locale, child: child);

  static AppLocale of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found in context');
    return scope!.notifier!;
  }
}
