import 'package:flutter/material.dart';
import 'package:diary/l10n/app_localizations.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.navActivities), centerTitle: true),
      body: Center(child: Text(t.comingSoon)),
    );
  }
}
