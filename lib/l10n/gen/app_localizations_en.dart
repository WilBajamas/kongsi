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
}
