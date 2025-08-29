import 'dart:convert';

class Activity {
  final int id;
  final String name;
  final String iconPath;
  final String description;
  final bool isCompleted;

  // コンストラクタなど...
  const Activity({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.isCompleted,
  });
  // JSONから変換するfactoryコンストラクタ...
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      iconPath: json['iconPath'],
      description: json['description'],
      isCompleted: json['isCompleted'],
    );
  }
  //オブジェクトをJSONの文字列形式に変換する
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'description': description,
      'isCompleted': isCompleted,
    };
  }
  //要素を動的にする
  Activity copyWith({
    int? id,
    String? name,
    String? iconPath,
    String? description,
    bool? isCompleted,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
