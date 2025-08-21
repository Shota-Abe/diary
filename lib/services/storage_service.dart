
import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_entry.dart';

class StorageService {
  static const _prefsKey = 'diary_entries_v1';

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
  }


}
