import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
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

  Future<String> saveImage(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}${_extensionOf(source.path)}';
    final target = File('${imagesDir.path}/$fileName');
    return (await source.copy(target.path)).path;
  }

  Future<String> saveImageBytes(Uint8List bytes, {String ext = '.png'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = 'draw_${DateTime.now().millisecondsSinceEpoch}$ext';
    final file = File('${imagesDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot);
  }
}
