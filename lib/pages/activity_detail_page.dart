// activity_detail_page.dart

import 'dart:convert';
import 'dart:io'; // Image.fileとFileクラスのために必要
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class ActivityDetailPage extends StatelessWidget {
  final Activity activity;

  const ActivityDetailPage({super.key, required this.activity});

  // [新規追加] 削除処理の本体
  Future<void> _deleteActivity(BuildContext context) async {
    // 1. SharedPreferencesから現在のリストを取得
    final prefs = await SharedPreferences.getInstance();
    final String? activitiesJson = prefs.getString('activities_list');
    if (activitiesJson == null) return; // データがなければ何もしない

    // 2. リストをデコードし、該当するIDの要素を削除
    List<dynamic> activitiesList = json.decode(activitiesJson);
    activitiesList.removeWhere((item) => item['id'] == activity.id);

    // 3. 削除後のリストを再度JSONに変換して保存
    await prefs.setString('activities_list', jsonEncode(activitiesList));

    // 4. 削除が完了したことを伝えながら前の画面に戻る
    if (context.mounted) {
      // pop(true)で前の画面に「削除が行われた」ことを伝える
      Navigator.of(context).pop(true);
    }
  }

  // [新規追加] 確認ダイアログを表示するメソッド
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('削除の確認'),
          content: Text('「${activity.name}」を本当に削除しますか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ダイアログを閉じる
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
              onPressed: () {
                // 先にダイアログを閉じてから削除処理を実行
                Navigator.of(dialogContext).pop();
                _deleteActivity(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // [修正] 画像表示ロジックをActivitiesPageと同様に修正
    Widget imageWidget;
    if (activity.iconPath.startsWith('assets/')) {
      imageWidget = Image.asset(
        activity.iconPath,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else {
      imageWidget = Image.file(
        File(activity.iconPath),
        fit: BoxFit.contain,
        width: double.infinity,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.name),
        // [新規追加] 右上に削除ボタンを配置
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '削除',
            onPressed: () {
              // ボタンが押されたら確認ダイアログを表示
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: imageWidget, // 修正したimageWidgetを使用
              ),
            ),
            const SizedBox(height: 24),
            Text(
              activity.name,
              // ... (以下、変更なし) ...
            ),
          ],
        ),
      ),
    );
  }
}
