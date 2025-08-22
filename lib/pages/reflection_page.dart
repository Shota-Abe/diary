import 'package:flutter/material.dart';

class ReflectionPage extends StatelessWidget {
  const ReflectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('振り返り'), centerTitle: true),
      body: const Center(child: Text('準備中…')),
    );
  }
}
