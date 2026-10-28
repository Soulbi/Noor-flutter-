import 'package:flutter/material.dart';
import '../core/i18n.dart';
import '../theme/app_theme.dart';

/// Stub for a module not ported to Flutter yet. Shows the tab's real title
/// (translated) so navigation already feels right while each screen is
/// filled in, phase by phase — see the task list for the build order.
class PlaceholderScreen extends StatelessWidget {
  final String titleKey;
  const PlaceholderScreen({super.key, required this.titleKey});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocaleScope.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: Text(locale.t(titleKey), style: fraunces(context))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            locale.t('comingSoon'),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.inkSoft, fontSize: 13.5),
          ),
        ),
      ),
    );
  }
}
