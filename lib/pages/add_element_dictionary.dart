import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddElementDictionary extends StatelessWidget {
  //図鑑の要素を追加するページ

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
              decoration: BoxDecoration( // 枠線などをつける場合
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child:TextField(
                decoration: InputDecoration(
                  hintText: 'アクティビティ'
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(8.0), // 内側に余白を持たせると見栄えが良くなります
              decoration: BoxDecoration( // 枠線などをつける場合
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child:TextField(
                decoration: InputDecoration(
                  hintText: '説明'
                ),
              ),
            ),

            ElevatedButton(
              child: Text('新規登録'),
              onPressed: (){
                
              }, 
            )
          ],
        )
      )
    );
  }
}
