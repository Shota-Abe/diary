import 'package:flutter/material.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アクティビティ'), centerTitle: true),
      body: const Center(child: Text('準備中…')),
    );
  }
}
