// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Kongsi';

  @override
  String get groupsEmpty => 'Tiada kumpulan lagi';

  @override
  String get createGroupTitle => 'Cipta kumpulan';

  @override
  String get groupNameLabel => 'Nama kumpulan';

  @override
  String get currencyLabel => 'Mata wang';

  @override
  String get cancel => 'Batal';

  @override
  String get create => 'Cipta';

  @override
  String get createGroupFailed => 'Kumpulan tidak dapat dicipta. Cuba lagi.';

  @override
  String syncProblemsBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perubahan tidak dapat disimpan',
    );
    return '$_temp0';
  }

  @override
  String get syncProblemsRetry => 'Cuba lagi';

  @override
  String get welcomePromise =>
      'Kongsi perbelanjaan dengan rakan. Walaupun di luar talian.';

  @override
  String get welcomeGetStarted => 'Mula sekarang';

  @override
  String get welcomeHaveAccount => 'Saya sudah ada akaun';

  @override
  String get signInTitle => 'Log masuk';

  @override
  String get signUpTitle => 'Cipta akaun';

  @override
  String get emailLabel => 'E-mel';

  @override
  String get passwordLabel => 'Kata laluan';

  @override
  String get authContinue => 'Teruskan';

  @override
  String get authLegalFootnote =>
      'Dengan meneruskan, anda bersetuju dengan terma dan dasar privasi kami.';

  @override
  String get emailInvalid => 'Masukkan e-mel yang sah untuk teruskan.';

  @override
  String get passwordTooShort => 'Gunakan sekurang-kurangnya 8 aksara.';

  @override
  String get authFailedCredentials => 'E-mel atau kata laluan salah.';

  @override
  String get authFailedNetwork =>
      'Tiada sambungan. Semak internet anda dan cuba lagi.';

  @override
  String get authFailedUnknown => 'Ada sesuatu yang tidak kena. Cuba lagi.';
}
