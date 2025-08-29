import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_entry.dart';

class StorageService {
  // シングルトン化して、全ページで同一のイベントストリームを共有する
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _prefsKey = 'diary_entries_v1';

  // 変更通知: エントリーが保存されたらイベントを流す
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();
  Stream<void> get changes => _changeController.stream;

  Future<List<DiaryEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    return list.map((e) => DiaryEntry.fromJson(e)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveEntries(List<DiaryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final list = entries.map((e) => e.toJson()).toList();
    await prefs.setStringList(_prefsKey, list);
    // 保存後に通知
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }
}
