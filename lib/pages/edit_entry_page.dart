
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/diary_entry.dart';

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
  // Image selection and drawing features removed

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _contentCtrl.text = e.content;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  // Photo picking and drawing handlers removed

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

    // Preserve existing imagePath if editing, but do not allow new image selection/drawing
    final String? imagePath = widget.entry?.imagePath;

    final entry = (widget.entry ??
        DiaryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _date,
          content: _contentCtrl.text.trim(),
          imagePath: imagePath,
        ))
      .copyWith(
        date: _date,
        content: _contentCtrl.text.trim(),
        imagePath: imagePath,
      );

    if (!mounted) return;
    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? '新規作成' : '編集'),
        actions: [
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
            // Image selection and drawing UI removed
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
