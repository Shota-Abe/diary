import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/activity.dart'; // 作成したモデルをインポート
import 'activity_detail_page.dart'; // 詳細ページ（後で作成）をインポート

// データを扱うためStatefulWidgetに変更
class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  // 非同期で取得するアクティビティのリストを保持する変数
  late Future<List<SummerActivity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    // 画面が作成された最初のタイミングでデータ読み込みを開始
    _activitiesFuture = _loadActivities();
  }

  // assetsからJSONを読み込み、SummerActivityのリストに変換するメソッド
  Future<List<SummerActivity>> _loadActivities() async {
    // 1. JSONファイルを文字列として読み込む
    final jsonString = await rootBundle.loadString(
      'assets/data/summer_activities.json',
    );
    // 2. 文字列をDartのList<Map>形式にデコード（解読）する
    final List<dynamic> jsonList = json.decode(jsonString);
    // 3. List<Map>の各要素をSummerActivity.fromJsonを使ってオブジェクトに変換する
    return jsonList.map((json) => SummerActivity.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('夏休みアクティビティ図鑑'), centerTitle: true),
      // FutureBuilderを使って、非同期処理（データ読み込み）の状態に応じて表示を切り替える
      body: FutureBuilder<List<SummerActivity>>(
        future: _activitiesFuture, // _loadActivitiesの完了を待つ
        builder: (context, snapshot) {
          // 状態1: 読み込み中の場合
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 状態2: エラーが発生した場合
          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }
          // 状態3: データの準備が完了した場合
          if (snapshot.hasData) {
            final activities = snapshot.data!;
            // GridViewを使ってデータをタイル状に表示する
            return GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 1行に表示するアイテム数
                crossAxisSpacing: 10.0, // アイテム間の横スペース
                mainAxisSpacing: 10.0, // アイテム間の縦スペース
              ),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];

                // isCompletedがfalseの時はアイコンをグレーにする
                final iconImage = ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    activity.isCompleted ? Colors.transparent : Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: Image.asset(activity.iconPath, fit: BoxFit.cover),
                );

                return GestureDetector(
                  onTap: () {
                    // タップされたら詳細ページに遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActivityDetailPage(activity: activity),
                      ),
                    );
                  },
                  child: GridTile(
                    footer: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      color: Colors.black.withOpacity(0.6),
                      child: Text(
                        activity.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blueGrey.shade700,
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: AssetImage(activity.iconPath),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: iconImage,
                    ),
                  ),
                );
              },
            );
          }
          // 状態4: データが空っぽの場合
          return const Center(child: Text('データがありません。'));
        },
      ),
    );
  }
}

k