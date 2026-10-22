// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tests => 'Tests';

  @override
  String get stats => 'Stats';

  @override
  String get classes => 'Classes';

  @override
  String get settings => 'Settings';

  @override
  String get noCamerasFound => 'No camera found on the device.';

  @override
  String get name => 'Name';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get system => 'System';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get alignAnswerKey => 'Align the answer key';

  @override
  String get newClass => 'New class';

  @override
  String get className => 'Class name';

  @override
  String get renameClass => 'Rename class';

  @override
  String get deleteClass => 'Delete class';

  @override
  String deleteClassConfirm(String name) {
    return 'This removes the class \"$name\" and all of its students.';
  }

  @override
  String get addStudent => 'Add student';

  @override
  String get studentName => 'Student name';

  @override
  String get studentExists => 'This student is already in the class';

  @override
  String get renameStudent => 'Rename student';

  @override
  String get deleteStudent => 'Delete student';

  @override
  String deleteStudentConfirm(String name) {
    return 'Remove \"$name\" from this class?';
  }

  @override
  String studentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '$count student',
      zero: '0 students',
    );
    return '$_temp0';
  }

  @override
  String get noClasses => 'No classes yet.\nTap + to create one.';

  @override
  String get noStudents => 'No students yet';

  @override
  String get classExists => 'A class with this name already exists';

  @override
  String get deleteTest => 'Delete test';

  @override
  String deleteTestConfirm(String name) {
    return 'This removes the test \"$name\" and all of its results.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get rename => 'Rename';

  @override
  String get open => 'Open';

  @override
  String get fieldEmpty => 'This field cannot be empty';

  @override
  String get testExists => 'A test with this name already exists';

  @override
  String get numberOfQuestions => 'Number of questions';

  @override
  String get numberOfOptions => 'Number of options';

  @override
  String get numberBoxTitle => 'Number box title';

  @override
  String get numberBoxDigits => 'Number box digit amount';

  @override
  String get minOne => 'Number has to be 1 or more';

  @override
  String get maxTen => 'Number has to be 10 or less';

  @override
  String get optionBoxTitle => 'Class box title';

  @override
  String get optionBoxOptions => 'Classes in the box';

  @override
  String get classOptionsHint =>
      'Type up to 5 classes. Existing classes are suggested as you type.';

  @override
  String get newTest => 'New test';

  @override
  String get saveTest => 'Save test';

  @override
  String get openGallery => 'Open gallery';

  @override
  String get classLabel => 'Class';

  @override
  String get average => 'Average';

  @override
  String get highestScore => 'Highest Score';

  @override
  String get lowestScore => 'Lowest Score';

  @override
  String get criticalAnalysis => 'Critical Analysis per Question';

  @override
  String mostCorrectTitle(String number) {
    return 'Question $number (Most correct)';
  }

  @override
  String mostWrongTitle(String number) {
    return 'Question $number (Most wrong)';
  }

  @override
  String classPercentTotal(String percent) {
    return '$percent% of the class';
  }

  @override
  String get asPng => 'as .png';

  @override
  String get asPdf => 'as .pdf';

  @override
  String get foundResults => 'Results found';

  @override
  String get studentNumber => 'Number';

  @override
  String get markedOption => 'Marked option';

  @override
  String get scoreLabel => 'Score';

  @override
  String get notAvailable => 'N/A';

  @override
  String get numberUncertain => 'Unreadable number - review the values';

  @override
  String get editValues => 'Edit values';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get numberWritten => 'Number (written)';

  @override
  String get cameraInitError => 'Could not start the camera.';

  @override
  String get back => 'Back';

  @override
  String get flashUnavailable => 'Flashlight unavailable on this device.';

  @override
  String readImageError(String error) {
    return 'Failed to read the image: $error';
  }

  @override
  String captureError(String error) {
    return 'Failed to capture: $error';
  }

  @override
  String get alignedReady => 'Aligned! Processing...';

  @override
  String get adjustSheet => 'Adjust the sheet';

  @override
  String linkedStudent(String name) {
    return 'Student: $name';
  }

  @override
  String linkedClass(String name) {
    return 'Class: $name';
  }

  @override
  String get notLinked => 'No class linked';
}
