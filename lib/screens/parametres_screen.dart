import 'package:flutter/material.dart';
import '../core/i18n.dart';
import '../core/theme_controller.dart';
import '../theme/app_theme.dart';

/// Minimal Paramètres screen for phase 1: theme mode, accent colour and
/// language — enough to exercise the whole theming/i18n system end to end.
/// Calculation method, Asr school and notification toggles are added once
/// the Prières and notifications modules land (see the task list).
class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocaleScope.of(context);
    final themeCtrl = AppThemeScope.of(context);
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: Text(locale.t('navParametres'), style: fraunces(context))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: locale.lang == AppLang.en ? 'Appearance' : 'Apparence',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModeRow(themeCtrl: themeCtrl),
                const SizedBox(height: 14),
                Text(locale.lang == AppLang.en ? 'Accent colour' : 'Couleur d\'accent',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.inkSoft, letterSpacing: .4)),
                const SizedBox(height: 8),
                _AccentRow(themeCtrl: themeCtrl),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: locale.lang == AppLang.en ? 'Language' : 'Langue',
            child: _LanguageRow(locale: locale),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.inkSoft, letterSpacing: .4)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final AppThemeController themeCtrl;
  const _ModeRow({required this.themeCtrl});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final options = {
      AppThemeMode.system: 'Auto',
      AppThemeMode.light: 'Clair',
      AppThemeMode.dark: 'Sombre',
    };
    return Wrap(
      spacing: 8,
      children: options.entries.map((e) {
        final selected = themeCtrl.mode == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          onSelected: (_) => themeCtrl.setMode(e.key),
          selectedColor: p.teal,
          labelStyle: TextStyle(color: selected ? Colors.white : p.ink, fontWeight: FontWeight.w600, fontSize: 12.5),
          backgroundColor: p.cardAlt,
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}

class _AccentRow extends StatelessWidget {
  final AppThemeController themeCtrl;
  const _AccentRow({required this.themeCtrl});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final options = [AppAccent.defaultTeal, AppAccent.indigo, AppAccent.bordeaux];
    return Row(
      children: options.map((a) {
        final swatch = AppPalette.resolve(brightness, a).teal;
        final selected = themeCtrl.accent == a;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => themeCtrl.setAccent(a),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? context.palette.ink : Colors.transparent, width: 2),
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppLocale locale;
  const _LanguageRow({required this.locale});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        _LangChip(label: 'Français', selected: locale.lang == AppLang.fr, onTap: () => locale.setLang(AppLang.fr), p: p),
        const SizedBox(width: 8),
        _LangChip(label: 'English', selected: locale.lang == AppLang.en, onTap: () => locale.setLang(AppLang.en), p: p),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette p;
  const _LangChip({required this.label, required this.selected, required this.onTap, required this.p});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: p.teal,
      labelStyle: TextStyle(color: selected ? Colors.white : p.ink, fontWeight: FontWeight.w600, fontSize: 12.5),
      backgroundColor: p.cardAlt,
      side: BorderSide.none,
    );
  }
}
