import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:table_calendar/table_calendar.dart';

import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import 'edit_entry_page.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  final _storage = StorageService();
  late Future<List<DiaryEntry>> _future;
  bool _calendarMode = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _future = _storage.loadEntries();
    _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _storage.loadEntries();
    });
  }

  Future<void> _addEntry() async {
    final entry = await Navigator.push<DiaryEntry>(
      context,
      MaterialPageRoute(builder: (_) => const EditEntryPage()),
    );
    if (entry != null) {
      final entries = await _storage.loadEntries();
      entries.add(entry);
      await _storage.saveEntries(entries);
      await _refresh();
    }
  }

  Future<void> _editEntry(DiaryEntry entry) async {
    final updated = await Navigator.push<DiaryEntry>(
      context,
      MaterialPageRoute(builder: (_) => EditEntryPage(entry: entry)),
    );
    if (updated != null) {
      final entries = await _storage.loadEntries();
      final idx = entries.indexWhere((e) => e.id == updated.id);
      if (idx != -1) entries[idx] = updated;
      await _storage.saveEntries(entries);
      await _refresh();
    }
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
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
    if (ok == true) {
      final entries = await _storage.loadEntries();
      entries.removeWhere((e) => e.id == entry.id);
      await _storage.saveEntries(entries);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日記'),
        actions: [
          IconButton(
            tooltip: _calendarMode ? 'リスト表示に切替' : 'カレンダー表示に切替',
            onPressed: () => setState(() => _calendarMode = !_calendarMode),
            icon: Icon(_calendarMode ? Icons.view_list : Icons.calendar_month),
          ),
        ],
      ),
      body: FutureBuilder<List<DiaryEntry>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data!;
          if (entries.isEmpty) {
            return const Center(child: Text('最初の日記を追加しましょう！'));
          }
          // グルーピング: 日付ごとにエントリ
          Map<DateTime, List<DiaryEntry>> byDay = {};
          for (final e in entries) {
            final d = DateTime(e.date.year, e.date.month, e.date.day);
            byDay.putIfAbsent(d, () => []).add(e);
          }

          if (_calendarMode) {
            final selected = _selectedDay;
            final selectedEntries = selected != null ? (byDay[selected] ?? []) : <DiaryEntry>[];

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TableCalendar<DiaryEntry>(
                      firstDay: DateTime(2000, 1, 1),
                      lastDay: DateTime(2100, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                      calendarFormat: CalendarFormat.month,
                      locale: 'ja_JP',
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      eventLoader: (day) {
                        final key = DateTime(day.year, day.month, day.day);
                        return byDay[key] ?? [];
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        markerDecoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.tertiary, shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                      ),
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    ),
                  ),
                  const Divider(height: 0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      selected != null ? DateFormat('yyyy/MM/dd').format(selected) : '日付を選択してください',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...selectedEntries.map((e) => _EntryCard(
                        entry: e,
                        onTap: () => _editEntry(e),
                        onLongPress: () => _deleteEntry(e),
                      )),
                  const SizedBox(height: 96),
                ],
              ),
            );
          }

          // リスト表示
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                return _EntryCard(
                  entry: e,
                  onTap: () => _editEntry(e),
                  onLongPress: () => _deleteEntry(e),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EntryCard({required this.entry, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.drawingBase64 != null || e.imagePath != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: kIsWeb
                    ? Image.memory(
                        base64Decode(e.drawingBase64!),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(e.imagePath!),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('yyyy/MM/dd').format(e.date), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      e.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
