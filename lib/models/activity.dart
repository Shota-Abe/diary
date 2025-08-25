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
}
