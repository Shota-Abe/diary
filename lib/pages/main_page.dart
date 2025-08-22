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
  final _pages = const [EntriesPage(), ActivitiesPage(), ReflectionPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: kReleaseMode
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
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
