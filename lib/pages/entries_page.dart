import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:diary/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import 'edit_entry_page.dart';
import 'drawing_editor.dart';

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
    _selectedDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _storage.loadEntries();
    });
  }

  Future<void> _addEntry() async {
    final entry = await Navigator.push<DiaryEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditEntryPage(),
        fullscreenDialog: true,
      ),
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
      MaterialPageRoute(
        builder: (_) => EditEntryPage(entry: entry),
        fullscreenDialog: true,
      ),
    );
    // Always refresh after returning (entry may have been deleted)
    if (updated != null) {
      final entries = await _storage.loadEntries();
      final idx = entries.indexWhere((e) => e.id == updated.id);
      if (idx != -1) entries[idx] = updated;
      await _storage.saveEntries(entries);
    }
    await _refresh();
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この操作は元に戻せません'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
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
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.navDiary),
        centerTitle: true,
        leading: IconButton(
          tooltip: t.feedbackButtonTooltip,
          onPressed: () async {
            final url = Uri.parse('https://forms.gle/L52ASxuy3TEc9Sqw9');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
            }
          },
          icon: const Icon(Icons.feedback_outlined),
        ),
        actions: [
          IconButton(
            tooltip: _calendarMode ? t.listViewTooltip : t.calendarViewTooltip,
            onPressed: () => setState(() => _calendarMode = !_calendarMode),
            icon: Icon(_calendarMode ? Icons.list_alt : Icons.calendar_month),
          ),
          const SizedBox(width: 8),
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
            return Center(child: Text(t.emptyEntries));
          }
          // グルーピング: 日付ごとにエントリ
          Map<DateTime, List<DiaryEntry>> byDay = {};
          for (final e in entries) {
            final d = DateTime(e.date.year, e.date.month, e.date.day);
            byDay.putIfAbsent(d, () => []).add(e);
          }

          if (_calendarMode) {
            final selected = _selectedDay;
            final selectedEntries = selected != null
                ? (byDay[selected] ?? [])
                : <DiaryEntry>[];

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
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDay),
                      calendarFormat: CalendarFormat.month,
                      locale: Localizations.localeOf(context).toLanguageTag(),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      eventLoader: (day) {
                        final key = DateTime(day.year, day.month, day.day);
                        return byDay[key] ?? [];
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = DateTime(
                            selectedDay.year,
                            selectedDay.month,
                            selectedDay.day,
                          );
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarBuilders: CalendarBuilders<DiaryEntry>(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return const SizedBox.shrink();
                          const double size = 4.0;
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ),
                  const Divider(height: 0),
                  ...selectedEntries.map(
                    (e) => _EntryCard(
                      entry: e,
                      onTap: () => _editEntry(e),
                      onDelete: () => _deleteEntry(e),
                    ),
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            );
          }

          // リスト表示（見出し: 日付）
          // entries は日付降順にソート済み
          final items = <_ListItem>[];
          DateTime? lastDate;
          for (final e in entries) {
            final day = DateTime(e.date.year, e.date.month, e.date.day);
            if (lastDate == null || !isSameDay(day, lastDate)) {
              items.add(_ListItem.header(day));
              lastDate = day;
            }
            items.add(_ListItem.entry(e));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return switch (item.type) {
                  _ListItemType.header => _DateHeader(date: item.date!),
                  _ListItemType.entry => _EntryCard(
                    entry: item.entry!,
                    onTap: () => _editEntry(item.entry!),
                    onDelete: () => _deleteEntry(item.entry!),
                  ),
                };
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: Text(t.add),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (direction) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('削除しますか？'),
            content: const Text('この操作は元に戻せません'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除'),
              ),
            ],
          ),
        );
        return ok == true;
      },
      onDismissed: (_) {
        onDelete();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.drawingJson != null && e.drawingJson!.trim().isNotEmpty)
                DrawingThumbnail(drawingJson: e.drawingJson!),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
      ),
    );
  }
}

enum _ListItemType { header, entry }

class _ListItem {
  final _ListItemType type;
  final DateTime? date;
  final DiaryEntry? entry;

  const _ListItem._(this.type, {this.date, this.entry});

  factory _ListItem.header(DateTime date) =>
      _ListItem._(_ListItemType.header, date: date);

  factory _ListItem.entry(DiaryEntry entry) =>
      _ListItem._(_ListItemType.entry, entry: entry);
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = DateFormat.yMMMMd(locale).format(date);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(),
          ),
        ],
      ),
    );
  }
}
