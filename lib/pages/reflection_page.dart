import 'package:flutter/material.dart';
import 'package:diary/l10n/app_localizations.dart';

class ReflectionPage extends StatelessWidget {
  const ReflectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.navReflection), centerTitle: true),
      body: Center(child: Text(t.comingSoon)),
    );
  }
}
