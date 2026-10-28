import 'package:flutter/material.dart';
import '../core/i18n.dart';
import 'placeholder_screen.dart';
import 'parametres_screen.dart';

/// The 5-tab bottom navigation shell, matching the web app's nav-btn row
/// (Accueil, Jeûne, Prières, Coran, Réglages). Each tab's real content is
/// added phase by phase — see placeholder_screen.dart for the stub used by
/// modules not ported yet.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocaleScope.of(context).t;
    final screens = [
      PlaceholderScreen(titleKey: 'navAccueil'),
      PlaceholderScreen(titleKey: 'navJeune'),
      PlaceholderScreen(titleKey: 'navPrieres'),
      PlaceholderScreen(titleKey: 'navCoran'),
      const ParametresScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: screens)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedFontSize: 11.5,
        unselectedFontSize: 11.5,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: t('navAccueil')),
          BottomNavigationBarItem(icon: const Icon(Icons.nights_stay_outlined), activeIcon: const Icon(Icons.nights_stay), label: t('navJeune')),
          BottomNavigationBarItem(icon: const Icon(Icons.schedule_outlined), activeIcon: const Icon(Icons.schedule), label: t('navPrieres')),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book_outlined), activeIcon: const Icon(Icons.menu_book), label: t('navCoran')),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), activeIcon: const Icon(Icons.settings), label: t('navParametres')),
        ],
      ),
    );
  }
}
