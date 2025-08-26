import 'dart:math';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// 一日の完成度を評価・表示するページ
///
/// 前のページから日記のテキスト(`diaryText`)を受け取ります。
class DayEvaluationPage extends StatefulWidget {
  final String diaryText;

  const DayEvaluationPage({
    super.key,
    required this.diaryText,
  });

  @override
  State<DayEvaluationPage> createState() => _DayEvaluationPageState();
}

class _DayEvaluationPageState extends State<DayEvaluationPage> {
  // --- State Variables ---
  bool _isLoading = true; // AIの評価処理中かどうかを管理するフラグ
  int _score = 0; // AIによって算出されたスコア
  String _comment = ''; // AIからのコメント

  @override
  void initState() {
    super.initState();
    // この画面が表示されたら、すぐにAIによる評価処理を開始する
    _evaluateDayByAI();
  }

  /// AIによる評価を実行する (ダミーの非同期処理)
  Future<void> _evaluateDayByAI() async {
    // 実際のAI APIを呼び出すことを想定し、3秒間待機してローディング画面を見せる
    await Future.delayed(const Duration(seconds: 3));

    // --- ここからがAIのダミーロジックです ---
    // 本来は `widget.diaryText` をAI APIに送信し、結果を受け取ります。
    // 今回は、日記の文字数に基づいてスコアとコメントを簡易的に生成します。
    final textLength = widget.diaryText.length;
    
    // 文字数が多いほどスコアが高くなるように計算 (最大100点)
    int calculatedScore = min(100, (textLength * 2.5).toInt());
    if (textLength < 5) calculatedScore = Random().nextInt(15); // 短すぎる場合はランダムな低得点

    // スコアに応じたコメントを生成
    String generatedComment;
    if (calculatedScore >= 90) {
      generatedComment = "素晴らしい一日でしたね！たくさんの経験が詰まった、最高の思い出です。";
    } else if (calculatedScore >= 70) {
      generatedComment = "とても充実した、良い一日だったようですね。明日も楽しみですね！";
    } else if (calculatedScore >= 40) {
      generatedComment = "まずまずの一日でしたね。小さな幸せを見つけられたようです。";
    } else {
      generatedComment = "今日は少しのんびりした日でしたか？ゆっくり休んで、また明日から頑張りましょう。";
    }
    // --- AIのダミーロジックはここまで ---

    // `mounted` をチェックして、ウィジェットがまだ画面に存在することを確認してから `setState` を呼ぶ
    if (mounted) {
      setState(() {
        _score = calculatedScore;
        _comment = generatedComment;
        _isLoading = false; // ローディング完了
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('一日の完成度'),
        backgroundColor: Colors.amber[100],
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: Center(
        // _isLoadingフラグの値に応じて、表示するウィジェットを切り替える
        child: _isLoading
            ? _buildLoadingView()   // ローディング中の表示
            : _buildResultView(),   // 評価結果の表示
      ),
    );
  }

  /// ローディング中に表示するウィジェット
  Widget _buildLoadingView() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24),
        Text(
          'AIが今日一日を評価中です...',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  /// 評価結果を表示するウィジェット
  Widget _buildResultView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '今日の完成度は...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // 円グラフでスコアを可視化
            CircularPercentIndicator(
              radius: 110.0,
              lineWidth: 18.0,
              percent: _score / 100.0, // パーセント (0.0 ~ 1.0)
              center: Text(
                '$_score点',
                style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              progressColor: Colors.amber,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1500,
            ),
            const SizedBox(height: 32),
            // AIからのコメント
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                _comment,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, height: 1.5),
              ),
            ),
            const SizedBox(height: 48),
            // 元の日記文章の表示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'あなたの日記：',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const Divider(height: 16),
                  Text(widget.diaryText),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // 前の画面（カレンダーなど）に戻る
              },
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
