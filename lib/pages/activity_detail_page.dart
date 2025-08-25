import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityDetailPage extends StatelessWidget {
  // 一覧画面から渡されるアクティビティのデータ
  final SummerActivity activity;

  const ActivityDetailPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(activity.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // アイコン画像を大きく表示
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  activity.iconPath,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // アクティビティ名
            Text(
              activity.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // 説明文
            Text(
              activity.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5, // 行間を少し広げる
              ),
            ),
          ],
        ),
      ),
    );
  }
}
