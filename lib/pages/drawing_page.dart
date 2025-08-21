import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingResult {
  final Uint8List pngBytes;
  final String drawingJson;
  const DrawingResult({required this.pngBytes, required this.drawingJson});
}

class DrawingPage extends StatefulWidget {
  final String? initialDrawingJson;

  const DrawingPage({super.key, this.initialDrawingJson});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _Stroke {
  _Stroke({required this.points, required this.color, required this.thickness});
  final List<Offset> points;
  final Color color;
  final double thickness;

  Map<String, dynamic> toMap() => {
        'color': color.value,
        'thickness': thickness,
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      };

  static _Stroke fromMap(Map<String, dynamic> map) => _Stroke(
        points: (map['points'] as List)
            .map((m) => Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble()))
            .toList(),
        color: Color(map['color'] as int),
        thickness: (map['thickness'] as num).toDouble(),
      );
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? current;
  _DrawingPainter(this.strokes, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _paintStroke(canvas, s);
    }
    if (current != null) {
      _paintStroke(canvas, current!);
    }
  }

  void _paintStroke(Canvas canvas, _Stroke stroke) {
    final p = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.thickness;
    final path = Path();
    if (stroke.points.isEmpty) return;
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.current != current;
}

class _DrawingController {
  final List<_Stroke> strokes = [];
  _Stroke? current;
  Color color = Colors.black;
  double thickness = 5.0;

  String toJson() => jsonEncode(strokes.map((s) => s.toMap()).toList());
  void loadJson(String json) {
    final list = jsonDecode(json) as List;
    strokes
      ..clear()
      ..addAll(list.map((m) => _Stroke.fromMap(m as Map<String, dynamic>)));
  }

  void start(Offset p) {
    current = _Stroke(points: [p], color: color, thickness: thickness);
  }

  void append(Offset p) {
    current?.points.add(p);
  }

  void end() {
    if (current != null) {
      strokes.add(current!);
      current = null;
    }
  }

  void undo() {
    if (strokes.isNotEmpty) {
      strokes.removeLast();
    }
  }
}

class _DrawingPageState extends State<DrawingPage> {
  final _ctrl = _DrawingController();
  final _repaintKey = GlobalKey();
  Color _bg = const Color(0xFFF2F2F2);

  @override
  void initState() {
    super.initState();
    if (widget.initialDrawingJson != null) {
      try {
        _ctrl.loadJson(widget.initialDrawingJson!);
      } catch (_) {}
    }
  }

  Future<Uint8List> _exportPng() async {
    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('絵を描く'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () async {
              final color = await showDialog<Color>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('色を選択'),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Colors.black,
                        Colors.red,
                        Colors.green,
                        Colors.blue,
                        Colors.orange,
                        Colors.purple,
                        Colors.brown,
                      ]
                          .map((c) => GestureDetector(
                                onTap: () => Navigator.pop(ctx, c),
                                child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              );
              if (color != null) setState(() => _ctrl.color = color);
            },
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => setState(_ctrl.undo),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final png = await _exportPng();
              final json = _ctrl.toJson();
              if (!mounted) return;
              Navigator.pop(context, DrawingResult(pngBytes: png, drawingJson: json));
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey)),
              child: RepaintBoundary(
                key: _repaintKey,
                child: GestureDetector(
                  onPanStart: (d) => setState(() => _ctrl.start(d.localPosition)),
                  onPanUpdate: (d) => setState(() => _ctrl.append(d.localPosition)),
                  onPanEnd: (_) => setState(() => _ctrl.end()),
                  child: CustomPaint(
                    painter: _DrawingPainter(_ctrl.strokes, _ctrl.current),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
 }
