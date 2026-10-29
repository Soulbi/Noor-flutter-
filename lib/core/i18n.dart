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

  // Prières screen — ported 1:1 from the web app's dictionary.
  'prieresLocateBtn': {AppLang.fr: 'Me localiser', AppLang.en: 'Use my location'},
  'prieresLocBanner': {
    AppLang.fr: 'Autorisez la géolocalisation pour des horaires calculés à votre position réelle. En attendant, les horaires ci-dessous utilisent Paris à titre d\'exemple.',
    AppLang.en: 'Allow location access for times calculated at your real position. Meanwhile, the times below use Paris as an example.',
  },
  'prieresUseGps': {AppLang.fr: 'Revenir à ma position (sans mosquée)', AppLang.en: 'Back to my location (no mosque)'},
  'prieresNextEyebrow': {AppLang.fr: 'Prochaine prière', AppLang.en: 'Next prayer'},
  'prieresMosquesTitle': {AppLang.fr: 'Mosquées à proximité', AppLang.en: 'Nearby mosques'},
  'prieresCalcTitle': {AppLang.fr: 'Méthode de calcul', AppLang.en: 'Calculation method'},
  'prieresCalcAngleLabel': {AppLang.fr: 'Angle Fajr / Isha', AppLang.en: 'Fajr / Isha angle'},
  'prieresCalcFrance': {AppLang.fr: 'Musulmans de France, ex-UOIF (12° / 12°)', AppLang.en: 'Muslims of France, ex-UOIF (12° / 12°)'},
  'prieresCalcMwl': {AppLang.fr: 'Ligue islamique mondiale (18° / 17°)', AppLang.en: 'Muslim World League (18° / 17°)'},
  'prieresCalcIsna': {AppLang.fr: 'ISNA (15° / 15°)', AppLang.en: 'ISNA (15° / 15°)'},
  'prieresCalcEgypt': {AppLang.fr: 'Autorité égyptienne (19,5° / 17,5°)', AppLang.en: 'Egyptian Authority (19.5° / 17.5°)'},
  'prieresCalcUqu': {AppLang.fr: 'Umm al-Qura (18,5° / 90 min après Maghrib)', AppLang.en: 'Umm al-Qura (18.5° / 90 min after Maghrib)'},
  'prieresCalcKarachi': {AppLang.fr: 'Karachi (18° / 18°)', AppLang.en: 'Karachi (18° / 18°)'},
  'prieresCalcAsrLabel': {AppLang.fr: 'École pour l\'Asr', AppLang.en: 'School for Asr'},
  'prieresCalcAsrStandard': {AppLang.fr: 'Standard (Chafi\'i, Maliki, Hanbali)', AppLang.en: 'Standard (Shafi\'i, Maliki, Hanbali)'},
  'prieresCalcAsrHanafi': {AppLang.fr: 'Hanafi', AppLang.en: 'Hanafi'},
  'prieresCalcNote': {
    AppLang.fr: 'Sans mosquée sélectionnée ci-dessus, les horaires sont calculés localement à partir de votre position, sans dépendre d\'un service externe. Une fois une mosquée choisie, le calcul utilise ses coordonnées exactes. La méthode « Musulmans de France » (12°/12°) est celle utilisée par la grande majorité des mosquées en France, notamment sur Mawaqit — si vos horaires ne correspondent pas à ceux de votre mosquée, vérifiez d\'abord qu\'elle n\'utilise pas une autre méthode dans la liste ci-dessus.',
    AppLang.en: 'With no mosque selected above, times are calculated locally from your position, without relying on an external service. Once a mosque is chosen, the calculation uses its exact coordinates. The "Muslims of France" method (12°/12°) is the one used by the vast majority of mosques in France, including on Mawaqit — if your times don\'t match your mosque\'s, check first whether it uses a different method from the list above.',
  },
  'mosqueSearching': {AppLang.fr: 'Recherche des mosquées à proximité…', AppLang.en: 'Looking for nearby mosques…'},
  'mosqueNone': {
    AppLang.fr: 'Aucune mosquée trouvée à proximité dans les données OpenStreetMap. Horaires calculés pour votre position.',
    AppLang.en: 'No mosque found nearby in OpenStreetMap data. Times calculated for your position.',
  },
  'mosqueError': {
    AppLang.fr: 'Impossible de charger la liste des mosquées pour le moment. Horaires calculés pour votre position.',
    AppLang.en: 'Couldn\'t load the mosque list right now. Times calculated for your position.',
  },
  'mosqueGeneric': {AppLang.fr: 'Mosquée', AppLang.en: 'Mosque'},
  'mosqueSelected': {AppLang.fr: 'sélectionnée', AppLang.en: 'selected'},
  'mosqueUsingFor': {AppLang.fr: 'Horaires calculés pour', AppLang.en: 'Times calculated for'},
  'retry': {AppLang.fr: 'Réessayer', AppLang.en: 'Retry'},
  'inMin': {AppLang.fr: 'Dans {n} min', AppLang.en: 'In {n} min'},
  'inHrMin': {AppLang.fr: 'Dans {h} h {m} min', AppLang.en: 'In {h} h {m} min'},
  'locUndefined': {AppLang.fr: 'Position non définie', AppLang.en: 'Location not set'},
  'locParisExample': {AppLang.fr: 'Paris (exemple)', AppLang.en: 'Paris (example)'},
  'locMine': {AppLang.fr: 'Ma position', AppLang.en: 'My location'},
  'locating': {AppLang.fr: 'Localisation…', AppLang.en: 'Locating…'},
  'locServiceDisabled': {
    AppLang.fr: 'Le GPS est désactivé sur cet appareil. Active-le dans les réglages pour utiliser ta position.',
    AppLang.en: 'Location services are off on this device. Turn them on in Settings to use your position.',
  },
  'locPermissionDenied': {
    AppLang.fr: 'Autorisation de localisation refusée.',
    AppLang.en: 'Location permission was denied.',
  },
  'locPermissionDeniedForever': {
    AppLang.fr: 'Autorisation de localisation bloquée — active-la dans les réglages de l\'application.',
    AppLang.en: 'Location permission is blocked — enable it in the app\'s system settings.',
  },
  'locUnavailable': {AppLang.fr: 'Position indisponible pour le moment.', AppLang.en: 'Location unavailable right now.'},
  'prayerSunrise': {AppLang.fr: 'Lever du soleil', AppLang.en: 'Sunrise'},
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

  /// Same as [t], but replaces `{name}` placeholders with [params] — used
  /// for the countdown strings ("Dans {n} min" / "In {n} min", etc.), same
  /// placeholder syntax as the web app's `t(key, {n: ...})`.
  String tParams(String key, Map<String, Object> params) {
    var s = t(key);
    params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
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
