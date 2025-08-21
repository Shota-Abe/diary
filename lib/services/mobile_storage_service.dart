import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class MobileStorageService {
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
}
