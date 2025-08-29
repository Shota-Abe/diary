import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary/l10n/app_localizations.dart';

// Removed painter package; now using custom DrawingPage with JSON strokes

import '../models/diary_entry.dart';
import 'drawing_editor.dart';
import '../services/storage_service.dart';

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
  final GlobalKey<DrawingEditorState> _drawingKey =
      GlobalKey<DrawingEditorState>();
  
  final _tagCtrl = TextEditingController();
  final List<String> _allTags = ['天気', '気分', '食事', '仕事', '趣味', 'お出かけ'];
  final Set<String> _selectedTags = <String>{};


  @override
  void initState() {
    super.initState();

    final e = widget.entry;
    if (e != null) {
      _contentCtrl.text = e.content;
      _date = e.date;
      _drawingJson = e.drawingJson;
      if (e.tags.isNotEmpty) {
        _selectedTags.addAll(e.tags);
        _tagCtrl.text = _selectedTags.join(', ');
      }
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _tagCtrl.dispose();
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
              tags: _selectedTags.toList(),
            );

    if (!mounted) return;
    Navigator.pop(context, entry);
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                DateFormat('yyyy/MM/dd').format(_date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            _buildDrawingCanvas(),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'タグ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _allTags.map((tag) {
                return ChoiceChip(
                  label: Text(tag),
                  selected: _selectedTags.contains(tag),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                      _tagCtrl.text = _selectedTags.join(', ');
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: _selectedTags.contains(tag) ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '選択されたタグがここに表示されます',
              ),
              readOnly: true,
            ),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 10,
              minLines: 5,
              decoration: InputDecoration(
                labelText: t.diaryLabel,
                border: const OutlineInputBorder(),
                hintText: t.diaryHint,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.diaryValidator : null,
            ),
          ],
        ),
      ),
    );
  }
}
