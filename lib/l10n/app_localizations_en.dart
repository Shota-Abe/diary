// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Diary';

  @override
  String get navDiary => 'Diary';

  @override
  String get navActivities => 'Activities';

  @override
  String get navReflection => 'Reflection';

  @override
  String get comingSoon => 'Coming soon…';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get confirmDeleteTitle => 'Delete this entry?';

  @override
  String get confirmDeleteContent => 'This action cannot be undone';

  @override
  String get listViewTooltip => 'Switch to list view';

  @override
  String get calendarViewTooltip => 'Switch to calendar view';

  @override
  String get emptyEntries => 'Let’s add your first diary!';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get diaryLabel => 'Diary';

  @override
  String get diaryHint => 'Write about your day and thoughts';

  @override
  String get diaryValidator => 'Please enter some content';

  @override
  String get thickness => 'Thickness';

  @override
  String get color => 'Color';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get clear => 'Clear';

  @override
  String get pickColorTitle => 'Pick a color';
}
