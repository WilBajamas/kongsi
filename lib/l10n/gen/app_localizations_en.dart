// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kongsi';

  @override
  String get groupsEmpty => 'No groups yet';

  @override
  String get createGroupTitle => 'Create group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get createGroupFailed => 'Could not create the group. Try again.';

  @override
  String syncProblemsBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes could not be saved',
      one: '1 change could not be saved',
    );
    return '$_temp0';
  }

  @override
  String get syncProblemsRetry => 'Retry';
}
