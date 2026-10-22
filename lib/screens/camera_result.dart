import 'package:flutter/material.dart';
import 'package:gabaretor/core/services/vision/image_parser.dart';
import 'package:gabaretor/core/storage_manager.dart';
import 'package:gabaretor/main.dart';
import 'package:gabaretor/widgets/answer_sheet.dart';

class ResultCandidate {
  final String studId;
  final int writNum;
  final String markOpt;
  final bool numberUncertain;
  final Map<String, Map<String, String>> answers;

  ResultCandidate({
    required this.studId,
    required this.writNum,
    required this.markOpt,
    this.numberUncertain = false,
    required this.answers,
  });
}

ResultCandidate buildResultCandidate(ParseOutput output, TestModel test) {
  final digits = output.numbers
      .map((e) => e.number >= 0 ? e.number.toString() : '?')
      .join();
  final numberUncertain = digits.contains('?');
  final rawId = digits.replaceAll('?', '');
  final writNum = numberUncertain ? 0 : (int.tryParse(rawId) ?? 0);

  String markOpt = '';
  final valid = output.optMarked.where((e) => e.index < test.opts.length);
  final marked = valid.where((e) => e.isMarked).toList();
  if (marked.isNotEmpty) {
    markOpt = test.opts[marked.first.index];
  } else {
    final ambiguous = valid.where((e) => e.isAmbiguous).toList();
    if (ambiguous.isNotEmpty) {
      markOpt = test.opts[ambiguous.first.index];
    }
  }

  final answers = <String, Map<String, String>>{};
  output.marks.forEach((qIdx, list) {
    final qKey = qIdx.toString();
    final markedIndex = list.indexWhere((e) => e.isMarked);
    if (markedIndex < 0) return;
    answers[qKey] = {'answer': String.fromCharCode(65 + markedIndex)};
  });

  return ResultCandidate(
    studId: rawId,
    writNum: writNum,
    markOpt: markOpt,
    numberUncertain: numberUncertain,
    answers: answers,
  );
}

int calcScore(Map<String, Map<String, String>> answers, TestModel test) {
  var score = 0;
  for (var q = 0; q < test.tQst; q++) {
    final qKey = q.toString();
    final correct = test.answers[qKey];
    final ans = answers[qKey];
    if (correct != null && ans != null && ans['answer'] == correct) score++;
  }
  return score;
}

Map<String, Map<String, String>> withCorrectness(
  Map<String, Map<String, String>> answers,
  TestModel test,
) {
  final out = <String, Map<String, String>>{};
  answers.forEach((q, value) {
    final letter =
        value['answer'] ?? (value.values.isNotEmpty ? value.values.first : '');
    final correct = test.answers[q];
    out[q] = {
      'answer': letter,
      'isCorrect': (correct != null && correct == letter).toString(),
    };
  });
  return out;
}

ClassModel? _resolveClass(String label) {
  final target = label.trim().toLowerCase();
  if (target.isEmpty) return null;
  for (final key in StorageManager.listAllKeys<ClassModel>()) {
    if (key.toLowerCase() == target) {
      return StorageManager.findEntry<ClassModel>(key);
    }
  }
  return null;
}

({ClassModel? cls, String? studentName}) resolveLink(ResultCandidate c) {
  final cls = _resolveClass(c.markOpt);
  String? student;
  if (cls != null) {
    final index = c.writNum - 1;
    if (index >= 0 && index < cls.students.length) {
      student = cls.students[index];
    }
  }
  return (cls: cls, studentName: student);
}

Future<String> saveResult(
  ResultCandidate candidate,
  TestModel test,
) async {
  final rawId = candidate.studId.isEmpty
      ? 'R_${DateTime.now().millisecondsSinceEpoch}'
      : candidate.studId;
  final link = resolveLink(candidate);
  final classId = link.cls?.classId ?? '';
  final studId = link.studentName ?? rawId;
  final answers = withCorrectness(candidate.answers, test);

  final result = ResultModel.fromMap(studId, {
    'studId': studId,
    'classId': classId,
    'testName': test.name,
    'writNum': candidate.writNum,
    'markOpt': candidate.markOpt,
    'score': calcScore(answers, test),
    'answers': answers,
  });

  StorageManager.saveEntry(result);
  return result.id;
}

Future<ResultCandidate?> editResult(
  BuildContext context,
  ResultCandidate candidate,
  TestModel test,
) async {
  final studCtrl = TextEditingController(text: candidate.studId);
  final markCtrl = TextEditingController(text: candidate.markOpt);
  final selection = <String, String>{};
  for (var q = 0; q < test.tQst; q++) {
    final qKey = q.toString();
    final answer = candidate.answers[qKey]?['answer'];
    if (answer != null && answer.isNotEmpty) selection[qKey] = answer;
  }

  return showDialog<ResultCandidate>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.editValues,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: studCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.l10n.numberWritten,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: markCtrl,
                          decoration: InputDecoration(
                            labelText: context.l10n.markedOption,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnswerSheet(
                          questionCount: test.tQst,
                          lettersPerQuestion: test.tLtr,
                          answers: selection,
                          onSelect: (q, letter) {
                            final key = q.toString();
                            setSt(() {
                              if (selection[key] == letter) {
                                selection.remove(key);
                              } else {
                                selection[key] = letter;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final num = int.tryParse(studCtrl.text.trim()) ?? 0;
                        final answers = <String, Map<String, String>>{};
                        for (var q = 0; q < test.tQst; q++) {
                          answers[q.toString()] = {
                            'answer': selection[q.toString()] ?? '',
                          };
                        }
                        final c = ResultCandidate(
                          studId: studCtrl.text.trim(),
                          writNum: num,
                          markOpt: markCtrl.text.trim(),
                          answers: answers,
                        );
                        Navigator.pop(ctx, c);
                      },
                      child: Text(context.l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
