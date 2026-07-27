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
}
