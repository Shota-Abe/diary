import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:diary/l10n/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DrawingResult {
  final Uint8List pngBytes;
  final String drawingJson;
  const DrawingResult({required this.pngBytes, required this.drawingJson});
}

/// A reusable inline drawing editor widget that can be embedded in any page.
/// Use a GlobalKey<DrawingEditorState> to call exportResult() when needed.
class DrawingEditor extends StatefulWidget {
  final String? initialDrawingJson;

  const DrawingEditor({super.key, this.initialDrawingJson});

  @override
  DrawingEditorState createState() => DrawingEditorState();
}

class DrawingEditorState extends State<DrawingEditor> {
  final _ctrl = _DrawingController();
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialDrawingJson != null) {
      try {
        _ctrl.loadJson(widget.initialDrawingJson!);
      } catch (_) {}
    }
  }

  bool get isEmpty => _ctrl.strokes.isEmpty && _ctrl.current == null;

  void clear() => setState(() => _ctrl.clearAll());

  Future<DrawingResult> exportResult() async {
    final boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final png = data!.buffer.asUint8List();
    final json = _ctrl.toJson();
    return DrawingResult(pngBytes: png, drawingJson: json);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.thickness),
            Expanded(
              child: Slider(
                value: _ctrl.thickness,
                min: 1,
                max: 20,
                onChanged: (v) => setState(() => _ctrl.thickness = v),
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.color,
              icon: const Icon(Icons.palette),
              onPressed: () async {
                final selected = await showDialog<Color>(
                  context: context,
                  builder: (ctx) {
                    Color temp = _ctrl.color;
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!.pickColorTitle),
                      content: StatefulBuilder(
                        builder: (context, setStateDialog) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ColorPicker(
                                pickerColor: temp,
                                onColorChanged: (c) =>
                                    setStateDialog(() => temp = c),
                                enableAlpha: false,
                                labelTypes: const [
                                  ColorLabelType.hsl,
                                  ColorLabelType.hex,
                                ],
                                paletteType: PaletteType.hslWithHue,
                                portraitOnly: true,
                              ),
                            ],
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(temp),
                          child: Text(AppLocalizations.of(context)!.ok),
                        ),
                      ],
                    );
                  },
                );
                if (selected != null) setState(() => _ctrl.color = selected);
              },
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.undo,
              icon: const Icon(Icons.undo),
              onPressed: () => setState(_ctrl.undo),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.redo,
              icon: const Icon(Icons.redo),
              onPressed: () => setState(_ctrl.redo),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: clear,
              child: Text(AppLocalizations.of(context)!.clear),
            ),
          ],
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: RepaintBoundary(
              key: _repaintKey,
              child: GestureDetector(
                onPanStart: (d) => setState(() => _ctrl.start(d.localPosition)),
                onPanUpdate: (d) =>
                    setState(() => _ctrl.append(d.localPosition)),
                onPanEnd: (_) => setState(() => _ctrl.end()),
                child: CustomPaint(
                  painter: _DrawingPainter(_ctrl.strokes, _ctrl.current),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Removed standalone DrawingPage (navigation-based editor) since the editor is now inline.

/// A lightweight, read-only thumbnail that renders a drawing from JSON strokes.
/// Used for list cards where we only need a preview image generated on the fly.
class DrawingThumbnail extends StatelessWidget {
  final String drawingJson;
  final double size;
  final BorderRadius borderRadius;
  final Color backgroundColor;

  const DrawingThumbnail({
    super.key,
    required this.drawingJson,
    this.size = 120,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(12),
      bottomLeft: Radius.circular(12),
    ),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: CustomPaint(painter: _ThumbnailPainter(drawingJson)),
      ),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  final String json;
  _ThumbnailPainter(this.json);

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final list = jsonDecode(json) as List;
      final strokes = list
          .map((m) => _Stroke.fromMap(m as Map<String, dynamic>))
          .toList();

      if (strokes.isEmpty) return;

      // Calculate bounds of all points
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = -double.infinity;
      double maxY = -double.infinity;
      double maxThickness = 0.0;
      for (final s in strokes) {
        if (s.thickness > maxThickness) maxThickness = s.thickness;
        for (final p in s.points) {
          if (p.dx < minX) minX = p.dx;
          if (p.dy < minY) minY = p.dy;
          if (p.dx > maxX) maxX = p.dx;
          if (p.dy > maxY) maxY = p.dy;
        }
      }

      final contentW = (maxX - minX).abs();
      final contentH = (maxY - minY).abs();
      if (contentW <= 0 || contentH <= 0) {
        _DrawingPainter(strokes, null).paint(canvas, size);
        return;
      }

      // Add padding so thick strokes are not clipped at the edges
      final padding = (maxThickness / 2.0) + 8.0; // extra safety margin
      final paddedW = contentW + padding * 2.0;
      final paddedH = contentH + padding * 2.0;

      final scaleX = (size.width / paddedW).clamp(0.0, double.infinity);
      final scaleY = (size.height / paddedH).clamp(0.0, double.infinity);
      final actualScale = scaleX < scaleY ? scaleX : scaleY;

      final dx = (size.width - paddedW * actualScale) / 2.0;
      final dy = (size.height - paddedH * actualScale) / 2.0;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.scale(actualScale, actualScale);
      // Shift origin to include padding around content
      canvas.translate(-(minX - padding), -(minY - padding));
      _DrawingPainter(strokes, null).paint(canvas, size);
      canvas.restore();
    } catch (_) {
      // ignore invalid json
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbnailPainter oldDelegate) =>
      oldDelegate.json != json;
}

class _Stroke {
  _Stroke({required this.points, required this.color, required this.thickness});
  final List<Offset> points;
  final Color color;
  final double thickness;

  Map<String, dynamic> toMap() => {
    'color': color.toARGB32(),
    'thickness': thickness,
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };

  static _Stroke fromMap(Map<String, dynamic> map) => _Stroke(
    points: (map['points'] as List)
        .map(
          (m) => Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble()),
        )
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
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

class _DrawingController {
  final List<_Stroke> strokes = [];
  _Stroke? current;
  Color color = Colors.black;
  double thickness = 5.0;
  final List<_Stroke> _redoStack = [];
  final List<List<_Stroke>> _clearHistory = [];
  final List<List<_Stroke>> _redoClearHistory = [];

  String toJson() => jsonEncode(strokes.map((s) => s.toMap()).toList());
  void loadJson(String json) {
    final list = jsonDecode(json) as List;
    strokes
      ..clear()
      ..addAll(list.map((m) => _Stroke.fromMap(m as Map<String, dynamic>)));
    _redoStack.clear();
    _clearHistory.clear();
    _redoClearHistory.clear();
    current = null;
  }

  void start(Offset p) {
    current = _Stroke(points: [p], color: color, thickness: thickness);
    // 新しい描画開始時はやり直し履歴を破棄
    _redoStack.clear();
    _redoClearHistory.clear();
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
      final removed = strokes.removeLast();
      _redoStack.add(removed);
      return;
    }
    if (_clearHistory.isNotEmpty) {
      final lastSnapshot = _clearHistory.removeLast();
      strokes
        ..clear()
        ..addAll(_cloneStrokes(lastSnapshot));
      _redoClearHistory.add(_cloneStrokes(lastSnapshot));
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final s = _redoStack.removeLast();
      strokes.add(s);
      return;
    }
    if (_redoClearHistory.isNotEmpty) {
      final snapshot = _redoClearHistory.removeLast();
      _applyClearForRedo(snapshot);
    }
  }

  void clearAll() {
    if (strokes.isNotEmpty) {
      _clearHistory.add(_cloneStrokes(strokes));
    }
    strokes.clear();
    current = null;
    _redoStack.clear();
    _redoClearHistory.clear();
  }

  List<_Stroke> _cloneStrokes(List<_Stroke> src) {
    return src
        .map(
          (s) => _Stroke(
            points: s.points.map((p) => Offset(p.dx, p.dy)).toList(),
            color: s.color,
            thickness: s.thickness,
          ),
        )
        .toList();
  }

  void _applyClearForRedo(List<_Stroke> snapshot) {
    // Redo: 再度クリアを適用する（クリア履歴に積み直す）
    if (strokes.isNotEmpty) {
      _clearHistory.add(_cloneStrokes(strokes));
    }
    strokes.clear();
    current = null;
    _redoStack.clear();
  }
}

// End of removal
