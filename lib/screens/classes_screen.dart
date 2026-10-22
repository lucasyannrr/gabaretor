import 'package:flutter/material.dart';
import 'package:gabaretor/core/storage_manager.dart';
import 'package:gabaretor/main.dart';

class ClassTab extends StatefulWidget {
  const ClassTab({super.key});

  @override
  State<ClassTab> createState() => _ClassTabState();
}

class _ClassTabState extends State<ClassTab> {
  void _refresh() => setState(() {});

  Future<String?> _askText({
    required String title,
    required String hint,
    String? initialValue,
    required FormFieldValidator<String> validator,
    IconData? icon,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: title,
        hint: hint,
        initialValue: initialValue,
        validator: validator,
        icon: icon,
        cancelLabel: context.l10n.cancel,
        saveLabel: context.l10n.save,
      ),
    );
  }

  Future<bool> _askConfirm({
    required String title,
    required String message,
    IconData icon = Icons.warning_amber_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(icon, color: Theme.of(dialogContext).colorScheme.error),
        title: Text(title),
        content: Text(message),
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

  Future<void> _createClass() async {
    final name = await _askText(
      title: context.l10n.newClass,
      hint: context.l10n.className,
      icon: Icons.group_add,
      validator: (value) {
        final trimmed = (value ?? '').trim();
        if (trimmed.isEmpty) return context.l10n.className;
        if (StorageManager.findEntry<ClassModel>(trimmed) != null) {
          return context.l10n.classExists;
        }
        return null;
      },
    );
    if (name == null || !mounted) return;
    StorageManager.saveEntry(ClassModel.fromMap(name, {}));
    _refresh();
  }

  Future<void> _renameClass(ClassModel model) async {
    final newName = await _askText(
      title: context.l10n.renameClass,
      hint: context.l10n.className,
      initialValue: model.classId,
      icon: Icons.edit_outlined,
      validator: (value) {
        final trimmed = (value ?? '').trim();
        if (trimmed.isEmpty) return context.l10n.className;
        if (trimmed != model.classId &&
            StorageManager.findEntry<ClassModel>(trimmed) != null) {
          return context.l10n.classExists;
        }
        return null;
      },
    );
    if (newName == null || newName == model.classId || !mounted) return;
    StorageManager.deleteEntry<ClassModel>(model.classId);
    StorageManager.saveEntry(ClassModel.fromMap(newName, {
      'students': model.students,
    }));
    StorageManager.renameClassInResults(model.classId, newName);
    StorageManager.renameClassInTests(model.classId, newName);
    _refresh();
  }

  Future<void> _deleteClass(ClassModel model) async {
    final confirmed = await _askConfirm(
      title: context.l10n.deleteClass,
      message: context.l10n.deleteClassConfirm(model.classId),
      icon: Icons.delete_outline,
    );
    if (!confirmed || !mounted) return;
    StorageManager.deleteEntry<ClassModel>(model.classId);
    StorageManager.deleteResultsForClass(model.classId);
    StorageManager.removeClassFromTests(model.classId);
    _refresh();
  }

  Future<void> _addStudent(ClassModel model) async {
    final name = await _askText(
      title: context.l10n.addStudent,
      hint: context.l10n.studentName,
      icon: Icons.person_add_alt,
      validator: (value) {
        final trimmed = (value ?? '').trim();
        if (trimmed.isEmpty) return context.l10n.studentName;
        if (model.students
            .any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
          return context.l10n.studentExists;
        }
        return null;
      },
    );
    if (name == null || !mounted) return;
    model.addStudent(name);
    StorageManager.saveEntry(model);
    _refresh();
  }

  Future<void> _renameStudent(ClassModel model, int index) async {
    final oldName = model.students[index];
    final name = await _askText(
      title: context.l10n.renameStudent,
      hint: context.l10n.studentName,
      initialValue: oldName,
      icon: Icons.edit_outlined,
      validator: (value) {
        final trimmed = (value ?? '').trim();
        if (trimmed.isEmpty) return context.l10n.studentName;
        for (var i = 0; i < model.students.length; i++) {
          if (i == index) continue;
          if (model.students[i].toLowerCase() == trimmed.toLowerCase()) {
            return context.l10n.studentExists;
          }
        }
        return null;
      },
    );
    if (name == null || !mounted) return;
    model.renameStudent(index, name);
    StorageManager.saveEntry(model);
    StorageManager.renameStudentInResults(model.classId, oldName, name);
    _refresh();
  }

  Future<void> _deleteStudent(ClassModel model, int index) async {
    final studentName = model.students[index];
    final confirmed = await _askConfirm(
      title: context.l10n.deleteStudent,
      message: context.l10n.deleteStudentConfirm(studentName),
      icon: Icons.person_remove,
    );
    if (!confirmed || !mounted) return;
    model.removeStudent(index);
    StorageManager.saveEntry(model);
    StorageManager.deleteResultsForStudent(model.classId, studentName);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final classes = StorageManager.listAllKeys<ClassModel>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.classes), centerTitle: true),
      body: classes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined, size: 64, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noClasses,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.outline),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final className = classes[index];
                final classModel = StorageManager.findEntry<ClassModel>(className);
                if (classModel == null) return const SizedBox.shrink();

                return Card(
                  key: ValueKey(className),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: const Icon(Icons.group),
                    ),
                    trailing: MenuAnchor(
                      menuChildren: [
                        MenuItemButton(
                          leadingIcon: const Icon(Icons.edit_outlined),
                          onPressed: () => _renameClass(classModel),
                          child: Text(context.l10n.rename),
                        ),
                        MenuItemButton(
                          leadingIcon: Icon(Icons.delete_outline, color: scheme.error),
                          onPressed: () => _deleteClass(classModel),
                          child: Text(
                            context.l10n.delete,
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      ],
                      builder: (context, controller, child) => IconButton(
                        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                        icon: const Icon(Icons.more_vert),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            className,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(context.l10n.studentCount(classModel.students.length)),
                    children: [
                      if (classModel.students.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            context.l10n.noStudents,
                            style: TextStyle(color: scheme.outline),
                          ),
                        )
                      else
                        for (var i = 0; i < classModel.students.length; i++) ...{
                          ListTile(
                            key: ValueKey('$className-$i'),
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: scheme.secondaryContainer,
                              foregroundColor: scheme.onSecondaryContainer,
                              child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                            ),
                            title: Text(classModel.students[i]),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  tooltip: context.l10n.edit,
                                  onPressed: () => _renameStudent(classModel, i),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
                                  tooltip: context.l10n.delete,
                                  onPressed: () => _deleteStudent(classModel, i),
                                ),
                              ],
                            ),
                          ),
                        },
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.add),
                            label: Text(context.l10n.addStudent),
                            onPressed: () => _addStudent(classModel),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_new_class',
        onPressed: _createClass,
        icon: const Icon(Icons.group_add),
        label: Text(context.l10n.newClass),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}