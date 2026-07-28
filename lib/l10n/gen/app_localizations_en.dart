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

  @override
  String get welcomePromise => 'Split expenses with friends. Even offline.';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomeHaveAccount => 'I have an account';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get authContinue => 'Continue';

  @override
  String get authLegalFootnote =>
      'By continuing you agree to our terms and privacy policy.';

  @override
  String get emailInvalid => 'Enter a valid email to continue.';

  @override
  String get passwordTooShort => 'Use at least 8 characters.';

  @override
  String get authFailedCredentials => 'Email or password is incorrect.';

  @override
  String get authFailedNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get authFailedUnknown => 'Something went wrong. Try again.';
}
