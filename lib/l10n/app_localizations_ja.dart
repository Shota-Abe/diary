// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '日記';

  @override
  String get navDiary => '日記';

  @override
  String get navActivities => 'アクティビティ';

  @override
  String get navReflection => '振り返り';

  @override
  String get comingSoon => '準備中…';

  @override
  String get add => '追加';

  @override
  String get feedbackButtonTooltip => 'フィードバックを送信';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get confirmDeleteTitle => '削除しますか？';

  @override
  String get confirmDeleteContent => 'この操作は元に戻せません';

  @override
  String get listViewTooltip => 'リスト表示に切替';

  @override
  String get calendarViewTooltip => 'カレンダー表示に切替';

  @override
  String get emptyEntries => '最初の日記を追加しましょう！';

  @override
  String get deleteTooltip => '削除';

  @override
  String get diaryLabel => '日記';

  @override
  String get diaryHint => '今日の出来事や感想を書きましょう';

  @override
  String get diaryValidator => '内容を入力してください';

  @override
  String get thickness => '太さ';

  @override
  String get color => '色';

  @override
  String get undo => '元に戻す';

  @override
  String get redo => 'やり直し';

  @override
  String get clear => 'クリア';

  @override
  String get pickColorTitle => '色を選択';

  @override
  String reflectionTitle(int year, int month) {
    return '$year年$month月の振り返り';
  }
}
