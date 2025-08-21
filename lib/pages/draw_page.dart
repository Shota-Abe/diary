import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawPage extends StatefulWidget {
  const DrawPage({super.key});

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final _paths = <_Stroke>[];
  _Stroke _current = _Stroke(color: Colors.black, width: 4.0);
  final _repaint = GlobalKey();

  void _start(Offset pos) {
    setState(() {
      _current = _Stroke(color: _current.color, width: _current.width, points: [pos]);
      _paths.add(_current);
    });
  }

  void _add(Offset pos) {
    setState(() {
      _current.points.add(pos);
    });
  }

  void _undo() {
    if (_paths.isNotEmpty) setState(() => _paths.removeLast());
  }

  void _clear() {
    setState(() => _paths.clear());
  }

  void _changeColor(Color c) {
    setState(() => _current = _Stroke(color: c, width: _current.width));
  }

  void _changeWidth(double w) {
    setState(() => _current = _Stroke(color: _current.color, width: w));
  }

  Future<void> _save() async {
    // RenderRepaintBoundary to image and then bytes PNG
    final boundary = _repaint.currentContext!.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    if (!mounted) return;
    Navigator.pop<Uint8List>(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お絵描き'),
        actions: [
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo)),
          IconButton(onPressed: _clear, icon: const Icon(Icons.layers_clear)),
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _repaint,
              child: GestureDetector(
                onPanStart: (d) => _start(d.localPosition),
                onPanUpdate: (d) => _add(d.localPosition),
                child: CustomPaint(
                  painter: _CanvasPainter(_paths),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
          _Toolbar(
            onColor: _changeColor,
            onWidth: _changeWidth,
            color: _current.color,
            width: _current.width,
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade300,
    );
  }
}

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke({this.points = const [], required this.color, required this.width});
}

class _CanvasPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _CanvasPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (int i = 1; i < s.points.length; i++) {
        canvas.drawLine(s.points[i - 1], s.points[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}

class _Toolbar extends StatelessWidget {
  final void Function(Color) onColor;
  final void Function(double) onWidth;
  final Color color;
  final double width;
  const _Toolbar({required this.onColor, required this.onWidth, required this.color, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final c in [Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onColor(c),
                child: CircleAvatar(backgroundColor: c, radius: 14, foregroundColor: Colors.white,
                  child: color == c ? const Icon(Icons.check, size: 16) : null,
                ),
              ),
            ),
          const Spacer(),
          const Icon(Icons.brush, size: 18),
          Slider(
            value: width,
            onChanged: onWidth,
            min: 1,
            max: 16,
            divisions: 15,
            label: width.toStringAsFixed(0),
          ),
        ],
      ),
    );
  }
}
