import 'dart:convert';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String content;
  final String? imagePath;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    this.imagePath,
  });

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    String? imagePath,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'imagePath': imagePath,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      content: map['content'] as String,
      imagePath: map['imagePath'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory DiaryEntry.fromJson(String source) => DiaryEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}
