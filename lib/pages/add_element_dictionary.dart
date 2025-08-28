import 'package:diary/models/activity.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart'; // アプリのディレクトリ取得
import 'package:path/path.dart' as path; // path.basename()などで使用
import 'package:shared_preferences/shared_preferences.dart'; // データ保存


class AddElementDictionary extends StatefulWidget{
  const AddElementDictionary({super.key});
  @override
  State<AddElementDictionary> createState() => _AddElementDictionaryState();
}



class _AddElementDictionaryState extends  State<AddElementDictionary>{
  //図鑑の要素を追加するページ

  //TextFieldの入力を保存する。
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _image;
  final _imagePicker = ImagePicker();

  
  @override//メモリを解放する。
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  //端末から画像を選択
  Future<void> _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;
    setState(() => _image = pickedImage);
  }

  // アクティビティを保存するメインの処理
  Future<void> _saveActivity() async {
    // ---- 1. 入力チェック ----
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全ての項目を入力してください')),
      );
      return;
    }

    // ---- 2. 画像をアプリのディレクトリにコピー ----
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(_image!.path); // 元のファイル名を取得
    final savedImage = await File(_image!.path).copy('${appDir.path}/$fileName');

    // ---- 3. SharedPreferencesのインスタンスを取得 ----
    final prefs = await SharedPreferences.getInstance();

    // ---- 4. 既存のリストを読み込む ----
    final String? activitiesJson = prefs.getString('activities_list');
    final List<dynamic> activitiesList = activitiesJson != null ? jsonDecode(activitiesJson) : [];

    // ---- 5. 新しいActivityオブジェクトを作成 ----
    final newActivity = Activity(
      id: activitiesList.length + 1, // シンプルなID採番
      name: _nameController.text,
      description: _descriptionController.text,
      iconPath: savedImage.path, // アプリ内にコピーした画像のパスを保存
       isCompleted: false,
    );

    // ---- 6. 新しいデータをリストに追加 ----
    activitiesList.add(newActivity.toJson());

    // ---- 7. 更新したリストをJSON文字列に変換して保存 ----
    await prefs.setString('activities_list', jsonEncode(activitiesList));

    // ---- 8. 完了をユーザーに通知して前の画面に戻る ----
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('アクティビティを登録しました！')),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('アクティビティを追加')),

      body: Container(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0), // 内側に余白を持たせると見栄えが良くなります
              decoration: BoxDecoration(
                // 枠線などをつける場合
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                decoration: InputDecoration(hintText: 'アクティビティ'),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(8.0), // 内側に余白を持たせると見栄えが良くなります
              decoration: BoxDecoration(
                // 枠線などをつける場合
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(decoration: InputDecoration(hintText: '説明')),
            ),

            Container(
              padding: const EdgeInsets.all(8.0), // 内側に余白を持たせると見栄えが良くなります
              decoration: BoxDecoration(
                // 枠線などをつける場合
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child:Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                     _pickImage();
                     },
                    child: Text('アイコンを選択'),
                  ),

                  _image==null
                    ? const Text('画像が選択されていません')
                    : Image.file(
                        File(_image!.path)
                      ),
                ]
              ),   
            ),

            ElevatedButton(child: Text('新規登録'), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
