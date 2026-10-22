import 'package:hive_ce_flutter/hive_ce_flutter.dart';

abstract class HiveModel {
  String get id;
  String get boxName;
  Map<String, dynamic> toMap();
}

extension HiveModelUtils on Type {
  String get boxName => switch (this) {
    TestModel => 'tests',
    ResultModel => 'results',
    ClassModel => 'classes',
    _ => throw ArgumentError('Unregistered type on Hive'),
  };

  HiveModel Function(String, Map) get fromMap => switch (this) {
    TestModel => (id, map) => TestModel.fromMap(id, map),
    ResultModel => (id, map) => ResultModel.fromMap(id, map),
    ClassModel => (id, map) => ClassModel.fromMap(id, map),
    _ => throw ArgumentError('Unregistered type on Hive'),
  };
}

class TestModel implements HiveModel {
  final String name;
  final int tQst;
  final int tLtr;
  final String nTtl;
  final int nAmt;
  final String oTtl;
  final List<String> opts;
  final Map<String, String> answers;

  static const String _box = 'tests';
  @override
  String get id => name;
  @override
  String get boxName => _box;

  TestModel.fromMap(this.name, Map<dynamic, dynamic> map) 
      : tQst = map['tQst'] ?? 0,
        tLtr = map['tLtr'] ?? 0,
        nTtl = map['nTtl'] ?? '',
        nAmt = map['nAmt'] ?? 0,
        oTtl = map['oTtl'] ?? '',
        opts = (map['opts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        answers = (map['answers'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {};
        
  @override
  Map<String, dynamic> toMap() => {
    'tQst': tQst,
    'tLtr': tLtr,
    'nTtl': nTtl,
    'nAmt': nAmt,
    'oTtl': oTtl,
    'opts': opts,
    'answers': answers,
  };
}

class ResultModel implements HiveModel {
  final String studId;
  final String classId;
  final String testName;
  final int writNum;
  final String markOpt;
  final int score;
  final Map<String, Map<String, String>> answers;

  static const String _box = 'results';
  @override
  String get id => '${classId}_${studId}_${writNum}_$testName';
  @override
  String get boxName => _box;

  ResultModel.fromMap(String id, Map<dynamic, dynamic> map)
      : studId = (map['studId'] ?? id).toString(),
        classId = (map['classId'] ?? '').toString(),
        testName = map['testName'] ?? '',
        writNum = map['writNum'] ?? 0,
        markOpt = map['markOpt'] ?? '',
        score = map['score'] ?? 0,
        answers = (map['answers'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(
          k.toString(), (v as Map<dynamic, dynamic>).map((innerKey, innerValue) => MapEntry(innerKey.toString(), innerValue.toString())),
        )) ?? {};
  
  @override
  Map<String, dynamic> toMap() => {
    'studId': studId,
    'classId': classId,
    'testName': testName,
    'writNum': writNum,
    'markOpt': markOpt,
    'score': score,
    'answers': answers,
  };
}

class ClassModel implements HiveModel {
  final String classId;
  final List<String> students;

  static const String _box = 'classes';
  @override
  String get id => classId;
  @override
  String get boxName => _box;

  ClassModel.fromMap(this.classId, Map<dynamic, dynamic> map)
      : students = map['students'] is List
            ? List<String>.from((map['students'] as List).map((e) => e.toString()))
            : [] {
    _sort();
  }

  @override
  Map<String, dynamic> toMap() => {'students': students};

  void _sort() => students.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  void addStudent(String name) => [students.add(name), _sort()];
  void renameStudent(int index, String name) => [students[index] = name, _sort()];
  void removeStudent(int index) => [students.removeAt(index), _sort()];

  (double, double, double, String, int, String, int) getClassTestPerformance(String testName) {
    final allResults = StorageManager.listAllEntries<ResultModel>();
    final classResults = allResults.where((result) => result.testName == testName && students.contains(result.studId));
    final classScores = classResults.map((result) => result.score.toDouble()).toList();

    if (classScores.isEmpty) return (0.0, 0.0, 0.0, '', 0, '', 0);

    double lowest = classScores.reduce((a, b) => a < b ? a : b);
    double highest = classScores.reduce((a, b) => a > b ? a : b);
    double sum = classScores.reduce((a, b) => a + b);
    double mean = sum / classScores.length;

    final correctCounts = <String, int>{};

    for (final result in classResults) {
      result.answers.forEach((questionId, details) {
        if (details['isCorrect'] == 'true') {
          correctCounts[questionId] = (correctCounts[questionId] ?? 0) + 1;
        } else {
          correctCounts[questionId] ??= 0;
        }
      });
    }

    if (correctCounts.isEmpty) return (mean, lowest, highest, '', 0, '', 0);

    final mostCorrect = correctCounts.entries.reduce((max, entry) => entry.value > max.value ? entry : max);
    final leastCorrect = correctCounts.entries.reduce((min, entry) => entry.value < min.value ? entry : min);

    return (mean, lowest, highest, mostCorrect.key, mostCorrect.value, leastCorrect.key, leastCorrect.value);
  }
}

class StorageManager {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(TestModel._box),
      Hive.openBox(ResultModel._box),
      Hive.openBox(ClassModel._box),
    ]);
  }

  static void saveEntry(HiveModel model) => Hive.box(model.boxName).put(model.id, model.toMap());

  static void deleteEntry<T extends HiveModel>(String key) => Hive.box(T.boxName).delete(key);

  static List<String> listAllKeys<T extends HiveModel>() => Hive.isBoxOpen(T.boxName)
      ? Hive.box(T.boxName).keys.cast<String>().toList()
      : <String>[];

  static T? findEntry<T extends HiveModel>(String key) {
    if (!Hive.isBoxOpen(T.boxName)) return null;
    final data = Hive.box(T.boxName).get(key);
    if (data == null) return null;

    return T.fromMap(key, data as Map) as T?;
  }

  static List<T> listAllEntries<T extends HiveModel>() => Hive.box(T.boxName).keys.map((key) => findEntry<T>(key.toString())).whereType<T>().toList();

  static List<ResultModel> resultsForTest(String testName) => listAllEntries<ResultModel>()
      .where((result) => result.testName == testName)
      .toList();

  static void deleteResultsForTest(String testName) {
    for (final result in resultsForTest(testName)) {
      deleteEntry<ResultModel>(result.id);
    }
  }

  static void renameTestInResults(String oldName, String newName) {
    for (final result in resultsForTest(oldName)) {
      final map = result.toMap();
      map['testName'] = newName;
      final updated = ResultModel.fromMap(result.studId, map);
      deleteEntry<ResultModel>(result.id);
      saveEntry(updated);
    }
  }

  static List<ResultModel> resultsForClass(String classId) => listAllEntries<ResultModel>()
      .where((result) => result.classId == classId)
      .toList();

  static List<ResultModel> resultsForStudent(String classId, String studentName) =>
      listAllEntries<ResultModel>()
          .where((result) =>
              result.classId == classId && result.studId == studentName)
          .toList();

  static void deleteResultsForClass(String classId) {
    for (final result in resultsForClass(classId)) {
      deleteEntry<ResultModel>(result.id);
    }
  }

  static void renameClassInResults(String oldName, String newName) {
    for (final result in resultsForClass(oldName)) {
      final map = result.toMap();
      map['classId'] = newName;
      final updated = ResultModel.fromMap(result.studId, map);
      deleteEntry<ResultModel>(result.id);
      saveEntry(updated);
    }
  }

  static void renameClassInTests(String oldName, String newName) {
    for (final key in listAllKeys<TestModel>()) {
      final test = findEntry<TestModel>(key);
      if (test == null || !test.opts.contains(oldName)) continue;
      final map = test.toMap();
      map['opts'] = test.opts.map((o) => o == oldName ? newName : o).toList();
      saveEntry(TestModel.fromMap(key, map));
    }
  }

  static void removeClassFromTests(String classId) {
    for (final key in listAllKeys<TestModel>()) {
      final test = findEntry<TestModel>(key);
      if (test == null || !test.opts.contains(classId)) continue;
      final map = test.toMap();
      map['opts'] = test.opts.where((o) => o != classId).toList();
      saveEntry(TestModel.fromMap(key, map));
    }
  }

  static void renameStudentInResults(
      String classId, String oldName, String newName) {
    for (final result in resultsForStudent(classId, oldName)) {
      final map = result.toMap();
      map['studId'] = newName;
      final updated = ResultModel.fromMap(newName, map);
      deleteEntry<ResultModel>(result.id);
      saveEntry(updated);
    }
  }

  static void deleteResultsForStudent(String classId, String studentName) {
    for (final result in resultsForStudent(classId, studentName)) {
      deleteEntry<ResultModel>(result.id);
    }
  }
}