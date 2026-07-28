import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
    Locale('zh'),
  ];

  /// App name shown in the OS task switcher.
  ///
  /// In en, this message translates to:
  /// **'Kongsi'**
  String get appTitle;

  /// Shown on the groups screen when the list is empty.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get groupsEmpty;

  /// Title of the create-group dialog.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupTitle;

  /// Label for the group name field.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameLabel;

  /// Label for the group currency field.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// Generic cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic create/submit button.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Error shown in the create-group dialog when saving fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create the group. Try again.'**
  String get createGroupFailed;

  /// App-wide banner shown when changes are stuck and can no longer sync.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change could not be saved} other{{count} changes could not be saved}}'**
  String syncProblemsBanner(int count);

  /// Button on the sync-problems banner that re-queues every stuck change.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get syncProblemsRetry;

  /// One-line value proposition on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Split expenses with friends. Even offline.'**
  String get welcomePromise;

  /// Primary button on the welcome screen; opens sign-up.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// Text button on the welcome screen; opens sign-in.
  ///
  /// In en, this message translates to:
  /// **'I have an account'**
  String get welcomeHaveAccount;

  /// Title of the auth screen in sign-in mode.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Title of the auth screen in sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpTitle;

  /// Label for the email field on the auth screen.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label for the password field on the auth screen.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Primary submit button on the auth screen.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// Legal footnote under the auth screen's submit button.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our terms and privacy policy.'**
  String get authLegalFootnote;

  /// Inline validation shown when the email field is empty or malformed.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email to continue.'**
  String get emailInvalid;

  /// Inline validation shown when the password is too short.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordTooShort;

  /// Shown when the server rejects the sign-in attempt.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authFailedCredentials;

  /// Shown when the sign-in attempt could not reach the server.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get authFailedNetwork;

  /// Fallback shown when a sign-in attempt fails for any other reason.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get authFailedUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
