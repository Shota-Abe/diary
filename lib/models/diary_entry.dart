import 'dart:convert';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String content;
  final String? drawingJson; // editable strokes data

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    this.drawingJson,
  });

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    String? drawingJson,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      drawingJson: drawingJson ?? this.drawingJson,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'drawingJson': drawingJson,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      content: map['content'] as String,
      drawingJson: map['drawingJson'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory DiaryEntry.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return DiaryEntry.fromMap(map);
  }
}
