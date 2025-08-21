
import 'package:flutter/material.dart';
import 'package:painter/painter.dart';

class DrawingPage extends StatefulWidget {
  final PainterController controller;

  const DrawingPage({super.key, required this.controller});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('絵を描く'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: widget.controller.undo,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final pictureDetails = widget.controller.finish();
              final bytes = await pictureDetails.toPNG();
              if (!mounted) return;
              Navigator.pop(context, bytes);
            },
          ),
        ],
      ),
      body: Painter(widget.controller),
    );
  }
}
