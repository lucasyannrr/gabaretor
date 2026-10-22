import 'package:flutter/material.dart';
import 'package:gabaretor/core/storage_manager.dart';
import 'package:gabaretor/core/range_formatter.dart';
import 'package:gabaretor/main.dart';
import 'package:gabaretor/screens/stats_screen.dart';
import 'package:gabaretor/widgets/answer_sheet.dart';

class TestsTab extends StatefulWidget {
  const TestsTab({super.key});

  @override
  State<TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends State<TestsTab> {
  void _refresh() => setState(() {});

  Future<bool> _confirmDelete(String testName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(context.l10n.deleteTest),
        content: Text(context.l10n.deleteTestConfirm(testName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tests = StorageManager.listAllKeys<TestModel>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tests), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tests.length,
        itemBuilder: (context, index) {
          final testName = tests[index];
          final testModel = StorageManager.findEntry<TestModel>(testName);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              onTap: () async {
                if (testModel != null) {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => StatsTab(test: testModel)));
                  _refresh();
                }
              },
              leading: const CircleAvatar(child: Icon(Icons.description)),
              title: Text(tests[index], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () async {
                      if (testModel != null) {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => StatsTab(test: testModel)));
                        _refresh();
                      }
                    },
                    child: Text(l10n.open),
                  ),
                  MenuItemButton(
                    onPressed: () async {
                      if (testModel != null) {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => SaveTestsTab(test: testModel)));
                        _refresh();
                      }
                    },
                    child: Text(l10n.edit),
                  ),
                  MenuItemButton(
                    onPressed: () async {
                      final confirmed = await _confirmDelete(testName);
                      if (!confirmed) return;
                      StorageManager.deleteResultsForTest(testName);
                      StorageManager.deleteEntry<TestModel>(testName);
                      _refresh();
                    },
                    child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
                  ),
                ],
                builder: (_, MenuController controller, Widget? child) {
                  return IconButton(
                    onPressed: () => (controller.isOpen) ? controller.close() : controller.open(),
                    icon: const Icon(Icons.more_vert),
                  );
                },
              )
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_new_test',
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => SaveTestsTab()));
          _refresh();
        },
        icon: const Icon(Icons.assignment_add),
        label: Text(l10n.newTest),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class SaveTestsTab extends StatefulWidget {
  final TestModel? test;
  const SaveTestsTab({super.key, this.test});

  @override
  State<SaveTestsTab> createState() => _SaveTestsTabState();
}


class _SaveTestsTabState extends State<SaveTestsTab> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _answers = {};
  late final Map<String, dynamic> _formData;

  late final ValueNotifier<int> _lettersNotifier;
  late final ValueNotifier<String> _optionTitleNotifier;

  final List<String> _optValues = List<String>.filled(5, '', growable: false);

  @override
  void initState() {
    super.initState();
    _formData = {
      "tQst": widget.test?.tQst ?? 0,
      "tLtr": widget.test?.tLtr ?? 0,
      "nTtl": widget.test?.nTtl ?? "",
      "nAmt": widget.test?.nAmt ?? 0,
      "oTtl": widget.test?.oTtl ?? "",
    };
    final initialOpts = widget.test?.opts ?? const <String>[];
    for (var i = 0; i < _optValues.length && i < initialOpts.length; i++) {
      _optValues[i] = initialOpts[i];
    }
    if (widget.test?.answers != null) _answers.addAll(widget.test!.answers);
    _lettersNotifier = ValueNotifier<int>(_formData["tLtr"] as int);
    _optionTitleNotifier = ValueNotifier<String>(_formData["oTtl"] as String? ?? '');
  }

  @override
  void dispose() {
    _lettersNotifier.dispose();
    _optionTitleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final classNames = StorageManager.listAllKeys<ClassModel>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tests), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12.0),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12.0,
              children: [
                TextFormField(
                  initialValue: widget.test?.name,
                  decoration: InputDecoration(labelText: l10n.name),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return l10n.fieldEmpty;
                    final trimmed = value.trim();
                    if (trimmed != widget.test?.name && StorageManager.findEntry<TestModel>(trimmed) != null) {
                      return l10n.testExists;
                    }
                    return null;
                  },
                  onSaved: (value) => _formData["name"] = value?.trim(),
                  maxLength: 50,
                ),
                TextFormField(
                  initialValue: widget.test != null ? _formData["tQst"].toString() : null,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.numberOfQuestions),
                  inputFormatters: [RangeTextInputFormatter(min: 1, max: 105)],
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldEmpty : null,
                  onChanged: (value) {
                    final val = int.tryParse(value) ?? 0;
                    if (_formData["tQst"] != val) {
                      setState(() => _formData["tQst"] = val);
                    }
                  },
                  onSaved: (value) => _formData["tQst"] = int.tryParse(value!) ?? 0,
                ),
                TextFormField(
                  initialValue: widget.test != null ? _formData["tLtr"].toString() : null,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.numberOfOptions),
                  inputFormatters: [RangeTextInputFormatter(min: 1, max: 5)],
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldEmpty : null,
                  onChanged: (value) {
                    final val = int.tryParse(value) ?? 0;
                    if (_lettersNotifier.value != val) {
                      _lettersNotifier.value = val;
                      _formData["tLtr"] = val;
                    }
                  },
                  onSaved: (value) => _formData["tLtr"] = int.tryParse(value!) ?? 0,
                ),
                TextFormField(
                  initialValue: _formData["nTtl"] as String?,
                  decoration: InputDecoration(labelText: l10n.numberBoxTitle),
                  onSaved: (value) => _formData["nTtl"] = value,
                  maxLength: 30,
                ),
                TextFormField(
                  initialValue: widget.test != null ? _formData["nAmt"].toString() : null,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.numberBoxDigits),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return l10n.fieldEmpty;
                    final parsed = int.tryParse(value) ?? 0;
                    if (parsed < 1) return l10n.minOne;
                    if (parsed > 10) return l10n.maxTen;
                    return null;
                  },
                  onSaved: (value) => _formData["nAmt"] = int.tryParse(value!) ?? 0,
                ),
                TextFormField(
                  initialValue: _formData["oTtl"] as String?,
                  decoration: InputDecoration(labelText: l10n.optionBoxTitle),
                  onChanged: (value) {
                    _formData["oTtl"] = value;
                    _optionTitleNotifier.value = value;
                  },
                  onSaved: (value) => _formData["oTtl"] = value,
                  maxLength: 30,
                ),
                ValueListenableBuilder<String>(
                  valueListenable: _optionTitleNotifier,
                  builder: (context, optionTitle, _) {
                    if (optionTitle.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12.0,
                      children: [
                        Text(
                          l10n.optionBoxOptions,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        ...List.generate(
                          _optValues.length,
                          (i) => _ClassOptionField(
                            label: '${l10n.classLabel} ${i + 1}',
                            initialValue: _optValues[i],
                            suggestions: classNames,
                            onChanged: (value) => _optValues[i] = value,
                          ),
                        ),
                        Text(
                          l10n.classOptionsHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<int>(
              valueListenable: _lettersNotifier,
              builder: (context, totalLetters, _) => AnswerSheet(
                questionCount: _formData["tQst"] as int,
                lettersPerQuestion: totalLetters,
                answers: _answers,
                onSelect: (q, letter) {
                  setState(() {
                    final key = q.toString();
                    if (_answers[key] == letter) {
                      _answers.remove(key);
                    } else {
                      _answers[key] = letter;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 88),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_save_test',
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState?.save();
            final newName = _formData["name"] as String;
            final oldName = widget.test?.name;
            if (oldName != null && oldName != newName) {
              StorageManager.deleteEntry<TestModel>(oldName);
              StorageManager.renameTestInResults(oldName, newName);
            }
            final opts = _optValues
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList();
            StorageManager.saveEntry(TestModel.fromMap(newName, {
              'name': newName,
              'tQst': _formData["tQst"],
              'tLtr': _formData["tLtr"],
              'nTtl': _formData["nTtl"],
              'nAmt': _formData["nAmt"],
              'oTtl': _formData["oTtl"],
              'opts': opts,
              'answers': _answers,
            }));
            Navigator.pop(context);
          }
        },
        label: Text(l10n.saveTest),
        icon: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _ClassOptionField extends StatelessWidget {
  final String label;
  final String initialValue;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  const _ClassOptionField({
    required this.label,
    required this.initialValue,
    required this.suggestions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return suggestions;
        return suggestions.where((s) => s.toLowerCase().contains(query));
      },
      displayStringForOption: (option) => option,
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label),
          onChanged: onChanged,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }
}
