import 'dart:convert';
import 'package:diary/pages/add_element_dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/activity.dart';
import 'activity_detail_page.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  // 変更可能なアクティビティのリストを保持する「状態」
  List<SummerActivity> activities = [];
  // 読み込み中かどうかを管理する「状態」
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // 画面の初回読み込み時にデータを取得
    _loadActivities();
  }

  // データを読み込み、状態を更新するメソッド
  Future<void> _loadActivities() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/summer_activities.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    final loadedActivities = jsonList
        .map((json) => SummerActivity.fromJson(json))
        .toList();

    // setStateを使って状態を更新し、画面の再描画をトリガーする
    setState(() {
      activities = loadedActivities;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('夏休みアクティビティ図鑑'),
        centerTitle: true,
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddElementDictionary()),
              );
            },
            child: Text('追加'),
          ),
        ],
      ),

      // isLoadingの状態に応じて表示を切り替える
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 読み込み中はインジケーターを表示
          : GridView.builder(
              // 読み込み完了後はGridViewを表示
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 見やすさのために3列に変更
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];

                final iconImage = ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    activity.isCompleted ? Colors.transparent : Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: Image.asset(activity.iconPath, fit: BoxFit.cover),
                );

                return GestureDetector(
                  // 🔽 ここがクリック処理の心臓部 🔽
                  onTap: () {
                    // setStateを呼び出すことで、Flutterに変更を通知し再描画を促す
                    setState(() {
                      // 1. タップされたアイテムのisCompletedを反転させた新しいオブジェクトを作成
                      final updatedActivity = activity.copyWith(
                        isCompleted: !activity.isCompleted,
                      );
                      // 2. リスト内の古いオブジェクトを新しいオブジェクトに置き換える
                      activities[index] = updatedActivity;
                    });
                  },
                  onLongPress: () {
                    // 長押しで詳細ページに遷移するように変更
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActivityDetailPage(activity: activity),
                      ),
                    );
                  },
                  child: GridTile(
                    // ... (GridTileの中身は変更なし) ...
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
            ),
    );
  }
}
