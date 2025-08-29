import 'dart:convert';
import 'package:diary/pages/add_element_dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import 'activity_detail_page.dart';
import 'dart:io';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  // 変更可能なアクティビティのリストを保持する「状態」
  List<Activity> activities = [];
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
    // 1. SharedPreferencesのインスタンスを取得
    final prefs = await SharedPreferences.getInstance();

    // 2. 'activities_list'キーで保存されたデータを取得
    final String? activitiesJson = prefs.getString('activities_list');

    List<Activity> loadedActivities;

    if (activitiesJson != null) {
      // 3. データがあれば、それをデコードしてリストに変換
      final List<dynamic> jsonList = json.decode(activitiesJson);
      loadedActivities = jsonList
          .map((json) => Activity.fromJson(json))
          .toList();
    } else {
      // 4. データがなければ（初回起動時など）、初期データをassetsから読み込む
      final initialJsonString = await rootBundle.loadString(
        'assets/data/summer_activities.json',
      );
      final List<dynamic> jsonList = json.decode(initialJsonString);
      loadedActivities = jsonList
          .map((json) => Activity.fromJson(json))
          .toList();

      // 5. 読み込んだ初期データをSharedPreferencesに保存しておく
      await prefs.setString('activities_list', initialJsonString);
    }

    // 取得したデータで状態を更新
    if (mounted) {
      setState(() {
        activities = loadedActivities;
        isLoading = false;
      });
    }
  }

  // ===== ▼ [新規追加] 完了状態をSharedPreferencesに保存するメソッド ▼ =====
  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    // 現在のリストをJSONに変換
    final List<Map<String, dynamic>> activitiesToSave =
        activities.map((activity) => activity.toJson()).toList();
    // SharedPreferencesに保存
    await prefs.setString('activities_list', jsonEncode(activitiesToSave));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('夏休みアクティビティ図鑑'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddElementDictionary()),
              );
              _loadActivities();
            },
            icon: const Icon(Icons.add),
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

                Widget imageWidget;
                if (activity.iconPath.startsWith('assets/')) {
                  // パスが 'assets/' で始まっていれば Image.asset を使用
                  imageWidget = Image.asset(activity.iconPath, fit: BoxFit.cover);
                } else {
                  // それ以外（ファイルパス）の場合は Image.file を使用
                  imageWidget = Image.file(File(activity.iconPath), fit: BoxFit.cover);
                }


                final iconImage = ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    activity.isCompleted ? Colors.transparent : Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: imageWidget,
                );

                return GestureDetector(
                  // 🔽 ここがクリック処理の心臓部 🔽
                  onTap: () async{
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivityDetailPage(activity: activity),
                     ),
                    );

                    if (result == true) {
                      _loadActivities();
                    }
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
                      child: Stack(
                        fit: StackFit.expand, // 子要素をStack全体に広げる
                        children: [
                          // 背景の画像
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6.0),
                            child: iconImage,
                          ),
                          // [変更点4] 右上に配置する完了ボタン
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(
                                // 完了状態に応じてアイコンと色を変更
                                activity.isCompleted
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: activity.isCompleted
                                  ? Colors.greenAccent
                                  : Colors.white.withOpacity(0.8),
                              ),
                              // アイコンの影で見やすくする
                              style: IconButton.styleFrom(
                                iconSize: 28,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                // ボタンが押されたら完了状態を反転させて保存
                                setState(() {
                                 final updatedActivity = activity.copyWith(
                                    isCompleted: !activity.isCompleted,
                                  );
                                  activities[index] = updatedActivity;
                                  _saveActivities();
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    ),

                  ),
                );
              },
            ),
    );
  }
}
