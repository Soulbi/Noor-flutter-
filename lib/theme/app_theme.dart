import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The three accent choices offered in Paramètres, matching the web app's
/// `data-accent` attribute ("" = teal/default, "indigo", "bordeaux").
enum AppAccent { defaultTeal, indigo, bordeaux }

/// A resolved set of design tokens for one (brightness, accent) combination.
/// These values are copied 1:1 from the CSS custom properties in the
/// existing web app (www/index.html :root blocks) so the Flutter version
/// looks identical, not just "similar".
class AppPalette {
  final Color bg;
  final Color card;
  final Color cardAlt;
  final Color ink;
  final Color inkSoft;
  final Color teal;
  final Color tealDeep;
  final Color tealTint;
  final Color gold;
  final Color goldTint;
  final Color line;
  final Color danger;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.ink,
    required this.inkSoft,
    required this.teal,
    required this.tealDeep,
    required this.tealTint,
    required this.gold,
    required this.goldTint,
    required this.line,
    required this.danger,
  });

  static const _lightBase = AppPalette(
    bg: Color(0xFFFAF7F0),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFF1EBDD),
    ink: Color(0xFF1C2B22),
    inkSoft: Color(0xFF5B6B60),
    teal: Color(0xFF0E4B3E),
    tealDeep: Color(0xFF0A362D),
    tealTint: Color(0xFFE4EEE9),
    gold: Color(0xFFB8862F),
    goldTint: Color(0xFFF5E9D0),
    line: Color(0xFFE2DAC8),
    danger: Color(0xFF9A3B32),
  );

  static const _darkBase = AppPalette(
    bg: Color(0xFF101613),
    card: Color(0xFF182019),
    cardAlt: Color(0xFF1C2620),
    ink: Color(0xFFEDE8DC),
    inkSoft: Color(0xFF9AA69D),
    teal: Color(0xFF3FA787),
    tealDeep: Color(0xFF2E7F65),
    tealTint: Color(0xFF1B3A30),
    gold: Color(0xFFD7A94B),
    goldTint: Color(0xFF3A2F1C),
    line: Color(0xFF2A342E),
    danger: Color(0xFFD96D62),
  );

  /// Returns the full palette for a given brightness + accent choice. Only
  /// teal/tealDeep/tealTint change with the accent — everything else stays
  /// the same, exactly mirroring the CSS [data-accent="…"] overrides.
  static AppPalette resolve(Brightness brightness, AppAccent accent) {
    final base = brightness == Brightness.dark ? _darkBase : _lightBase;
    switch (accent) {
      case AppAccent.defaultTeal:
        return base;
      case AppAccent.indigo:
        return brightness == Brightness.dark
            ? base._withTeal(const Color(0xFF8593DE), const Color(0xFF5F6DB8), const Color(0xFF232A4A))
            : base._withTeal(const Color(0xFF2B3F82), const Color(0xFF1E2C5C), const Color(0xFFE4E7F6));
      case AppAccent.bordeaux:
        return brightness == Brightness.dark
            ? base._withTeal(const Color(0xFFDD8B98), const Color(0xFFB45F6C), const Color(0xFF3A2226))
            : base._withTeal(const Color(0xFF7D2A3B), const Color(0xFF5C1E2A), const Color(0xFFF6E4E7));
    }
  }

  AppPalette _withTeal(Color teal, Color tealDeep, Color tealTint) {
    return AppPalette(
      bg: bg,
      card: card,
      cardAlt: cardAlt,
      ink: ink,
      inkSoft: inkSoft,
      teal: teal,
      tealDeep: tealDeep,
      tealTint: tealTint,
      gold: gold,
      goldTint: goldTint,
      line: line,
      danger: danger,
    );
  }
}

/// Builds the Flutter [ThemeData] for one palette. Headings use Fraunces
/// (serif), body text Public Sans — same pairing as the web app. Arabic
/// text (Quran) should use [arabicTextStyle] rather than the default theme
/// font, same as the `.arabic` CSS class does today.
ThemeData buildAppTheme(AppPalette p, Brightness brightness) {
  final publicSans = GoogleFonts.publicSansTextTheme();
  final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();

  return base.copyWith(
    brightness: brightness,
    scaffoldBackgroundColor: p.bg,
    colorScheme: (brightness == Brightness.dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: p.teal,
      onPrimary: Colors.white,
      secondary: p.gold,
      surface: p.card,
      onSurface: p.ink,
      error: p.danger,
    ),
    textTheme: publicSans.apply(bodyColor: p.ink, displayColor: p.ink),
    fontFamily: GoogleFonts.publicSans().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: p.ink),
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.line),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: p.card,
      selectedItemColor: p.teal,
      unselectedItemColor: p.inkSoft,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1),
    extensions: [AppPaletteExtension(p)],
  );
}

/// Exposes the raw [AppPalette] through the Theme, for the many small UI
/// details (pills, swatches, hero gradients…) that reference a specific
/// token directly rather than a generic Material role.
class AppPaletteExtension extends ThemeExtension<AppPaletteExtension> {
  final AppPalette palette;
  const AppPaletteExtension(this.palette);

  @override
  AppPaletteExtension copyWith({AppPalette? palette}) => AppPaletteExtension(palette ?? this.palette);

  @override
  AppPaletteExtension lerp(ThemeExtension<AppPaletteExtension>? other, double t) {
    // Palettes are swapped instantly (theme/accent change), not animated
    // between arbitrary colors, so no interpolation is needed.
    if (other is! AppPaletteExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPaletteExtension>()!.palette;
}

/// Text style for Arabic Quran text — mirrors the `.arabic` CSS rule
/// (Noto Naskh Arabic, falling back to Public Sans).
TextStyle arabicTextStyle(BuildContext context, {double fontSize = 24}) {
  return GoogleFonts.notoNaskhArabic(fontSize: fontSize, color: context.palette.ink, height: 2);
}

TextStyle fraunces(BuildContext context, {double fontSize = 20, FontWeight weight = FontWeight.w600, Color? color}) {
  return GoogleFonts.fraunces(fontSize: fontSize, fontWeight: weight, color: color ?? context.palette.ink);
}
