class SummerActivity {
  final int id;
  final String name;
  final String iconPath;
  final String description;
  final bool isCompleted;

  // コンストラクタなど...
  const SummerActivity({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.isCompleted,
  });
  // JSONから変換するfactoryコンストラクタ...
  factory SummerActivity.fromJson(Map<String, dynamic> json) {
    return SummerActivity(
      id: json['id'],
      name: json['name'],
      iconPath: json['iconPath'],
      description: json['description'],
      isCompleted: json['isCompleted'],
    );
  }
}
