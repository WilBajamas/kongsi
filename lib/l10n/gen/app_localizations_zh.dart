// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Kongsi';

  @override
  String get groupsEmpty => '还没有群组';

  @override
  String get createGroupTitle => '创建群组';

  @override
  String get groupNameLabel => '群组名称';

  @override
  String get currencyLabel => '货币';

  @override
  String get cancel => '取消';

  @override
  String get create => '创建';

  @override
  String get createGroupFailed => '无法创建群组，请重试。';
}
