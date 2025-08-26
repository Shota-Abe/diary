import 'package:flutter/material.dart';
import 'DayEvaluation_page.dart'; // 先ほど作成した評価ページをインポート

/// DayEvaluationPageをテストするための簡易的なテキスト入力ページ
class TextEntryPage extends StatefulWidget {
  const TextEntryPage({super.key});

  @override
  State<TextEntryPage> createState() => _TextEntryPageState();
}

class _TextEntryPageState extends State<TextEntryPage> {
  // TextFieldの入力を管理するためのコントローラー
  final _textController = TextEditingController();

  @override
  void dispose() {
    // ページが破棄される際にコントローラーも破棄する
    _textController.dispose();
    super.dispose();
  }

  /// 評価ページへ画面遷移するメソッド
  void _navigateToEvaluationPage() {
    // DayEvaluationPageに画面遷移し、入力されたテキストを渡す
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayEvaluationPage(
          diaryText: _textController.text, // TextFieldの現在のテキストを渡す
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テスト入力ページ'),
        backgroundColor: Colors.teal[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // テキスト入力フィールド
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'AIに評価させたい文章を入力',
                border: OutlineInputBorder(),
                hintText: '例：今日は公園でたくさん遊んで楽しかった。',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            // 画面遷移ボタン
            ElevatedButton(
              onPressed: _navigateToEvaluationPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('この内容で評価ページへ進む'),
            ),
          ],
        ),
      ),
    );
  }
}
