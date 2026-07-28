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

  @override
  String syncProblemsBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项更改无法保存',
    );
    return '$_temp0';
  }

  @override
  String get syncProblemsRetry => '重试';

  @override
  String get welcomePromise => '和朋友分摊开销，离线也能用。';

  @override
  String get welcomeGetStarted => '开始使用';

  @override
  String get welcomeHaveAccount => '我已有账号';

  @override
  String get signInTitle => '登录';

  @override
  String get signUpTitle => '创建账号';

  @override
  String get emailLabel => '邮箱';

  @override
  String get passwordLabel => '密码';

  @override
  String get authContinue => '继续';

  @override
  String get authLegalFootnote => '继续即表示你同意我们的条款和隐私政策。';

  @override
  String get emailInvalid => '请输入有效的邮箱以继续。';

  @override
  String get passwordTooShort => '请使用至少 8 个字符。';

  @override
  String get authFailedCredentials => '邮箱或密码不正确。';

  @override
  String get authFailedNetwork => '无网络连接。请检查网络后重试。';

  @override
  String get authFailedUnknown => '出了点问题，请重试。';
}
