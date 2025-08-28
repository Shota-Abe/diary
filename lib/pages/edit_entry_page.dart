import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary/l10n/app_localizations.dart';

// Removed painter package; now using custom DrawingPage with JSON strokes

import '../models/diary_entry.dart';
import 'drawing_editor.dart';
import '../services/storage_service.dart';
import 'snackbar_helper.dart';

class EditEntryPage extends StatefulWidget {
  final DiaryEntry? entry;
  const EditEntryPage({super.key, this.entry});

  @override
  State<EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<EditEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  DateTime _date = DateTime.now();
  Uint8List? _drawingBytes;
  String? _drawingJson; // editable strokes data
  final GlobalKey<DrawingEditorState> _drawingKey =
      GlobalKey<DrawingEditorState>();

  @override
  void initState() {
    super.initState();

    final e = widget.entry;
    if (e != null) {
      _contentCtrl.text = e.content;
      _date = e.date;
      _drawingJson = e.drawingJson;
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Inline drawing editor is used instead of navigating to another page.

  Future<void> _pickDate() async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final initial = _date.isAfter(today) ? today : _date;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: today,
      selectableDayPredicate: (day) =>
          day.isBefore(today) ||
          day.year == today.year &&
              day.month == today.month &&
              day.day == today.day,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    String? drawingJson = widget.entry?.drawingJson;

    // Export from inline editor if it has content
    if (_drawingKey.currentState != null &&
        !_drawingKey.currentState!.isEmpty) {
      final result = await _drawingKey.currentState!.exportResult();
      _drawingBytes = result.pngBytes;
      _drawingJson = result.drawingJson;
    }

    if (_drawingBytes != null) {
      // 現在はサムネイル生成を行わず、編集可能なJSONのみ保存
      drawingJson = _drawingJson;
    }

    final entry =
        (widget.entry ??
                DiaryEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: _date,
                  content: _contentCtrl.text.trim(),
                ))
            .copyWith(
              date: _date,
              content: _contentCtrl.text.trim(),
              drawingJson: drawingJson,
            );

    if (!mounted) return;
    Navigator.pop(context, entry);

    assert(() {
      showAppSnackBar(context, 2);
      return true;
    }());
  }

  Widget _buildDrawingCanvas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DrawingEditor(key: _drawingKey, initialDrawingJson: _drawingJson),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          const SizedBox(width: 8),

          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(t.cancel),
          ),

          const Spacer(),

          if (widget.entry != null)
            TextButton(
              child: Text(t.delete),
              onPressed: () async {
                final currentContext = context;
                final ok = await showDialog<bool>(
                  context: currentContext,
                  builder: (_) => AlertDialog(
                    title: Text(t.confirmDeleteTitle),
                    content: Text(t.confirmDeleteContent),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(currentContext, false),
                        child: Text(t.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(currentContext, true),
                        child: Text(t.delete),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  if (!currentContext.mounted) return;
                  // 実データを削除
                  final storage = StorageService();
                  final list = await storage.loadEntries();
                  list.removeWhere((e) => e.id == widget.entry!.id);
                  await storage.saveEntries(list);
                  // 画像ファイル等の後片付けは不要になった
                  if (!currentContext.mounted) return;
                  Navigator.pop(currentContext, null);
                }
              },
            ),

          TextButton(onPressed: _save, child: Text(t.save)),

          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        left: true,
        right: true,
        top: false,
        bottom: false,
        child: Form(
          key: _formKey,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _scrollCtrl,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('yyyy/MM/dd').format(_date)),
                  ),
                  const SizedBox(height: 12),
                  _buildDrawingCanvas(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentCtrl,
                    maxLines: 10,
                    minLines: 5,
                    decoration: InputDecoration(
                      labelText: t.diaryLabel,
                      border: const OutlineInputBorder(),
                      hintText: t.diaryHint,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? t.diaryValidator
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
