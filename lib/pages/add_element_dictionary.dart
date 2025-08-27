import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddElementDictionary extends StatefulWidget{
  const AddElementDictionary({super.key});
  @override
  State<AddElementDictionary> createState() => _AddElementDictionaryState();
}



class _AddElementDictionaryState extends  State<AddElementDictionary>{
  //図鑑の要素を追加するページ

  XFile? image; //画像ファイルを格納する変数
  final imagePicker = ImagePicker();

  //端末から画像を選択
  Future pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    // 画像がnullの場合戻る
    if (image == null) return;
    final imageTemp = XFile(image.path);

    //画像ファイルをimage変数に格納
    setState(() => this.image = imageTemp);
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
                     pickImage();
                     },
                    child: Text('アイコンを選択'),
                  ),

                  image==null
                    ? const Text('画像が選択されていません')
                    : Image.file(File(image!.path)),
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
