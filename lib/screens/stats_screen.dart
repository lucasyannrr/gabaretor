import 'package:flutter/material.dart';
import 'package:gabaretor/core/storage_manager.dart';
import 'package:gabaretor/core/services/generation/answer_key.dart';
import 'package:gabaretor/main.dart';
import 'package:gabaretor/screens/camera_screen.dart';

class StatsTab extends StatefulWidget {
  final TestModel test;
  const StatsTab({super.key, required this.test});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  String? _selectedOpt;

  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    final options = widget.test.opts;
    if (options.isNotEmpty) {
      _selectedOpt = options.first.toString();
    }
  }

  void _handleDownload(bool inPng) {
    AnswerKey.exportAnswerKey(
      widget.test.name, widget.test.tQst, widget.test.tLtr,
      nTtl: widget.test.nTtl, nAmt: widget.test.nAmt,
      oTtl: widget.test.oTtl, opts: widget.test.opts,
      inPng: inPng
    );
  }

  ClassModel? _getClass(String key) => StorageManager.findEntry<ClassModel>(key);

  String _percent(int count, int total) {
    if (total <= 0) return '0';
    return ((count / total) * 100).round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final options = widget.test.opts;
    final ClassModel? currentClass = _selectedOpt != null ? _getClass(_selectedOpt!) : null;
    final scoreStats = currentClass?.getClassTestPerformance(widget.test.name);
    final int studentCount = currentClass?.students.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.stats),
        centerTitle: true,
        actions: [
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.image),
                onPressed: () => _handleDownload(true),
                child: Text(context.l10n.asPng),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _handleDownload(false),
                child: Text(context.l10n.asPdf),
              ),
            ],
            builder: (context, controller, child) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: const Icon(Icons.download)
              );
            },
          )
        ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (options.isNotEmpty) DropdownButtonFormField<String>(
              initialValue: _selectedOpt,
              items: [
                ...options.map((opt) => DropdownMenuItem(
                  value: opt.toString(),
                  child: Text(opt.toString()),
                ))
              ],
              onChanged: (val) => setState(() => _selectedOpt = val),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                labelText: context.l10n.classLabel,
              ),
            ),
            const SizedBox(height: 24),

            if (currentClass != null) ...[
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(child: Column(children: [Text(context.l10n.average, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)), Text(scoreStats!.$1.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])),
                      Expanded(child: Column(children: [Text(context.l10n.highestScore, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)), Text(scoreStats.$2.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green))])),
                      Expanded(child: Column(children: [Text(context.l10n.lowestScore, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)), Text(scoreStats.$3.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red))])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(context.l10n.criticalAnalysis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                title: Text(context.l10n.mostCorrectTitle(scoreStats.$4.isNotEmpty ? scoreStats.$4 : context.l10n.notAvailable)),
                subtitle: Text(context.l10n.classPercentTotal(_percent(scoreStats.$5, studentCount))),
              ),
              LinearProgressIndicator(value: studentCount > 0 ? scoreStats.$5 / studentCount : 0, color: Colors.green, backgroundColor: scheme.surfaceContainerHighest),
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red, size: 32),
                title: Text(context.l10n.mostWrongTitle(scoreStats.$6.isNotEmpty ? scoreStats.$6 : context.l10n.notAvailable)),
                subtitle: Text(context.l10n.classPercentTotal(_percent(scoreStats.$7, studentCount))),
              ),
              LinearProgressIndicator(value: studentCount > 0 ? scoreStats.$7 / studentCount : 0, color: Colors.red, backgroundColor: scheme.surfaceContainerHighest),
            ] else Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.l10n.noStudents,
                style: TextStyle(color: scheme.outline),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_stats',
        onPressed: () async {
          if (cameras.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.noCamerasFound)));
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CameraScreen(camera: cameras.first, test: widget.test)),
          );
          _refresh();
        },
        child: Icon(Icons.document_scanner),
      ),
    );
  }
}