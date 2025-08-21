
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:typed_data';

// Removed painter package; now using custom DrawingPage with JSON strokes

import '../models/diary_entry.dart';
import 'drawing_editor.dart';
import '../services/storage_service.dart';
import '../services/mobile_storage_service.dart';

class EditEntryPage extends StatefulWidget {
  final DiaryEntry? entry;
  const EditEntryPage({super.key, this.entry});

  @override
  State<EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<EditEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  Uint8List? _drawingBytes;
  String? _drawingJson; // editable strokes data
  final GlobalKey<DrawingEditorState> _drawingKey = GlobalKey<DrawingEditorState>();
  final _mobileStorage = MobileStorageService();

  @override
  void initState() {
    super.initState();

    final e = widget.entry;
    if (e != null) {
      _contentCtrl.text = e.content;
      _date = e.date;
      _drawingJson = e.drawingJson;
      if (kIsWeb) {
        if (e.drawingBase64 != null) {
          _drawingBytes = base64Decode(e.drawingBase64!);
        }
      } else {
        if (e.imagePath != null) {
          // Load image data from file path
          File(e.imagePath!).readAsBytes().then((bytes) {
            if (mounted) setState(() => _drawingBytes = bytes);
          });
        }
      }
    }
  }

  @override
  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  // Inline drawing editor is used instead of navigating to another page.


  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    String? imagePath = widget.entry?.imagePath;
    String? drawingBase64 = widget.entry?.drawingBase64;
    String? drawingJson = widget.entry?.drawingJson;

    // Export from inline editor if it has content
    if (_drawingKey.currentState != null && !_drawingKey.currentState!.isEmpty) {
      final result = await _drawingKey.currentState!.exportResult();
      _drawingBytes = result.pngBytes;
      _drawingJson = result.drawingJson;
    }

    if (_drawingBytes != null) {
      if (kIsWeb) {
        drawingBase64 = base64Encode(_drawingBytes!);
        imagePath = null; // Do not use file path for web
      } else {
        imagePath = await _mobileStorage.saveImageBytes(_drawingBytes!);
        drawingBase64 = null; // Do not use base64 for mobile
      }
      drawingJson = _drawingJson; // save editable strokes
    }

    final entry = (widget.entry ??
            DiaryEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              date: _date,
              content: _contentCtrl.text.trim(),
            ))
        .copyWith(
      date: _date,
      content: _contentCtrl.text.trim(),
      imagePath: imagePath,
      drawingBase64: drawingBase64,
      drawingJson: drawingJson,
    );

    if (!mounted) return;
    Navigator.pop(context, entry);
  }

  Widget _buildDrawingCanvas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('今日の絵', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DrawingEditor(key: _drawingKey, initialDrawingJson: _drawingJson),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? '新規作成' : '編集'),
        actions: [
          if (widget.entry != null)
            IconButton(
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('削除しますか？'),
                    content: const Text('この操作は元に戻せません'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
                    ],
                  ),
                );
                if (ok == true && mounted) {
                  // 実データを削除
                  final storage = StorageService();
                  final list = await storage.loadEntries();
                  list.removeWhere((e) => e.id == widget.entry!.id);
                  await storage.saveEntries(list);
                  // 可能なら画像ファイルも削除
                  final path = widget.entry!.imagePath;
                  if (path != null) {
                    try { File(path).exists().then((exists) { if (exists) File(path).delete(); }); } catch (_) {}
                  }
                  if (!mounted) return;
                  Navigator.pop(context, null);
                }
              },
            ),
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(DateFormat('yyyy/MM/dd').format(_date), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 12),
                OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_today), label: const Text('日付を変更')),
              ],
            ),
            const SizedBox(height: 12),
            _buildDrawingCanvas(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 10,
              minLines: 5,
              decoration: const InputDecoration(
                labelText: '日記',
                border: OutlineInputBorder(),
                hintText: '今日の出来事や感想を書きましょう',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? '内容を入力してください' : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('保存')),
          ],
        ),
      ),
    );
  }
}
