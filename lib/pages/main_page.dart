import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:diary/l10n/app_localizations.dart';

import 'activities_page.dart';
import 'entries_page.dart';
import 'reflection_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  // Pages are built dynamically depending on build mode

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const EntriesPage(),
      const ActivitiesPage(),
      const ReflectionPage(),
    ];

    int currentIndex = _currentIndex;
    if (currentIndex >= pages.length) {
      currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.book),
            label: AppLocalizations.of(context)!.navDiary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_run),
            label: AppLocalizations.of(context)!.navActivities,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: AppLocalizations.of(context)!.navReflection,
          ),
        ],
      ),
    );
  }
}
