import 'package:flutter/material.dart';

import 'activities_page.dart';
import 'entries_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final _pages = const [EntriesPage(), ActivitiesPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book),
            label: '日記',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run),
            label: 'アクティビティ',
          ),
        ],
      ),
    );
  }
}
