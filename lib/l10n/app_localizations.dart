import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('pt'),
  ];

  /// No description provided for @tests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get tests;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @classes.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classes;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @noCamerasFound.
  ///
  /// In en, this message translates to:
  /// **'No camera found on the device.'**
  String get noCamerasFound;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @alignAnswerKey.
  ///
  /// In en, this message translates to:
  /// **'Align the answer key'**
  String get alignAnswerKey;

  /// No description provided for @newClass.
  ///
  /// In en, this message translates to:
  /// **'New class'**
  String get newClass;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get className;

  /// No description provided for @renameClass.
  ///
  /// In en, this message translates to:
  /// **'Rename class'**
  String get renameClass;

  /// No description provided for @deleteClass.
  ///
  /// In en, this message translates to:
  /// **'Delete class'**
  String get deleteClass;

  /// No description provided for @deleteClassConfirm.
  ///
  /// In en, this message translates to:
  /// **'This removes the class \"{name}\" and all of its students.'**
  String deleteClassConfirm(String name);

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add student'**
  String get addStudent;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student name'**
  String get studentName;

  /// No description provided for @studentExists.
  ///
  /// In en, this message translates to:
  /// **'This student is already in the class'**
  String get studentExists;

  /// No description provided for @renameStudent.
  ///
  /// In en, this message translates to:
  /// **'Rename student'**
  String get renameStudent;

  /// No description provided for @deleteStudent.
  ///
  /// In en, this message translates to:
  /// **'Delete student'**
  String get deleteStudent;

  /// No description provided for @deleteStudentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from this class?'**
  String deleteStudentConfirm(String name);

  /// No description provided for @studentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 students} one{{count} student} other{{count} students}}'**
  String studentCount(int count);

  /// No description provided for @noClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes yet.\nTap + to create one.'**
  String get noClasses;

  /// No description provided for @noStudents.
  ///
  /// In en, this message translates to:
  /// **'No students yet'**
  String get noStudents;

  /// No description provided for @classExists.
  ///
  /// In en, this message translates to:
  /// **'A class with this name already exists'**
  String get classExists;

  /// No description provided for @deleteTest.
  ///
  /// In en, this message translates to:
  /// **'Delete test'**
  String get deleteTest;

  /// No description provided for @deleteTestConfirm.
  ///
  /// In en, this message translates to:
  /// **'This removes the test \"{name}\" and all of its results.'**
  String deleteTestConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @fieldEmpty.
  ///
  /// In en, this message translates to:
  /// **'This field cannot be empty'**
  String get fieldEmpty;

  /// No description provided for @testExists.
  ///
  /// In en, this message translates to:
  /// **'A test with this name already exists'**
  String get testExists;

  /// No description provided for @numberOfQuestions.
  ///
  /// In en, this message translates to:
  /// **'Number of questions'**
  String get numberOfQuestions;

  /// No description provided for @numberOfOptions.
  ///
  /// In en, this message translates to:
  /// **'Number of options'**
  String get numberOfOptions;

  /// No description provided for @numberBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Number box title'**
  String get numberBoxTitle;

  /// No description provided for @numberBoxDigits.
  ///
  /// In en, this message translates to:
  /// **'Number box digit amount'**
  String get numberBoxDigits;

  /// No description provided for @minOne.
  ///
  /// In en, this message translates to:
  /// **'Number has to be 1 or more'**
  String get minOne;

  /// No description provided for @maxTen.
  ///
  /// In en, this message translates to:
  /// **'Number has to be 10 or less'**
  String get maxTen;

  /// No description provided for @optionBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Class box title'**
  String get optionBoxTitle;

  /// No description provided for @optionBoxOptions.
  ///
  /// In en, this message translates to:
  /// **'Classes in the box'**
  String get optionBoxOptions;

  /// No description provided for @classOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Type up to 5 classes. Existing classes are suggested as you type.'**
  String get classOptionsHint;

  /// No description provided for @newTest.
  ///
  /// In en, this message translates to:
  /// **'New test'**
  String get newTest;

  /// No description provided for @saveTest.
  ///
  /// In en, this message translates to:
  /// **'Save test'**
  String get saveTest;

  /// No description provided for @openGallery.
  ///
  /// In en, this message translates to:
  /// **'Open gallery'**
  String get openGallery;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLabel;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @highestScore.
  ///
  /// In en, this message translates to:
  /// **'Highest Score'**
  String get highestScore;

  /// No description provided for @lowestScore.
  ///
  /// In en, this message translates to:
  /// **'Lowest Score'**
  String get lowestScore;

  /// No description provided for @criticalAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Critical Analysis per Question'**
  String get criticalAnalysis;

  /// No description provided for @mostCorrectTitle.
  ///
  /// In en, this message translates to:
  /// **'Question {number} (Most correct)'**
  String mostCorrectTitle(String number);

  /// No description provided for @mostWrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Question {number} (Most wrong)'**
  String mostWrongTitle(String number);

  /// No description provided for @classPercentTotal.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the class'**
  String classPercentTotal(String percent);

  /// No description provided for @asPng.
  ///
  /// In en, this message translates to:
  /// **'as .png'**
  String get asPng;

  /// No description provided for @asPdf.
  ///
  /// In en, this message translates to:
  /// **'as .pdf'**
  String get asPdf;

  /// No description provided for @foundResults.
  ///
  /// In en, this message translates to:
  /// **'Results found'**
  String get foundResults;

  /// No description provided for @studentNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get studentNumber;

  /// No description provided for @markedOption.
  ///
  /// In en, this message translates to:
  /// **'Marked option'**
  String get markedOption;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @numberUncertain.
  ///
  /// In en, this message translates to:
  /// **'Unreadable number - review the values'**
  String get numberUncertain;

  /// No description provided for @editValues.
  ///
  /// In en, this message translates to:
  /// **'Edit values'**
  String get editValues;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @numberWritten.
  ///
  /// In en, this message translates to:
  /// **'Number (written)'**
  String get numberWritten;

  /// No description provided for @cameraInitError.
  ///
  /// In en, this message translates to:
  /// **'Could not start the camera.'**
  String get cameraInitError;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @flashUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Flashlight unavailable on this device.'**
  String get flashUnavailable;

  /// No description provided for @readImageError.
  ///
  /// In en, this message translates to:
  /// **'Failed to read the image: {error}'**
  String readImageError(String error);

  /// No description provided for @captureError.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture: {error}'**
  String captureError(String error);

  /// No description provided for @alignedReady.
  ///
  /// In en, this message translates to:
  /// **'Aligned! Processing...'**
  String get alignedReady;

  /// No description provided for @adjustSheet.
  ///
  /// In en, this message translates to:
  /// **'Adjust the sheet'**
  String get adjustSheet;

  /// No description provided for @linkedStudent.
  ///
  /// In en, this message translates to:
  /// **'Student: {name}'**
  String linkedStudent(String name);

  /// No description provided for @linkedClass.
  ///
  /// In en, this message translates to:
  /// **'Class: {name}'**
  String linkedClass(String name);

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'No class linked'**
  String get notLinked;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
