import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

typedef AnswerKeyData = (
  pw.Widget numberWidget,
  pw.Widget optionWidget,
  pw.Widget answerKeyWidget,
  List<Rect> numberROIs,
  List<Rect> optionROIs,
  Map<int, List<Rect>> questionROIs,
);

typedef GeneratedAnswerKey = ({
  Uint8List pdfBytes,
  List<Rect> numberROIs,
  List<Rect> optionROIs,
  Map<int, List<Rect>> questionROIs,
});

class AnswerKey {
  static final PdfPageFormat defaultA4Page = PdfPageFormat.a4.applyMargin(left: 24, top: 24, right: 24, bottom: 24);
  static const double _anchorSize = 26.0;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static Future<GeneratedAnswerKey> generateAnswerKeyData(int qNum, int lNum, {String nTtl = "", int nAmt = 0, String oTtl = "", List<String> opts = const []}) async {
    final regularData = await rootBundle.load("assets/fonts/Gabarito-Regular.ttf");
    final boldData = await rootBundle.load("assets/fonts/Gabarito-Bold.ttf");

    final fontTheme = pw.ThemeData.withFont(base: pw.Font.ttf(regularData), bold: pw.Font.ttf(boldData));
    final pdf = pw.Document(theme: fontTheme);

    final letters = _optNumToLetterList(lNum);
    int maxQuestionsPerColumn = (qNum / 3).ceil();

    double bubbleSize = 16;
    double fontSize = 8;
    double qPadding = 2;
    double topBarScale = 1;

    if (qNum <= 20) {
      maxQuestionsPerColumn = 20;
      final t = ((qNum - 10) / 10).clamp(0.0, 1.0);
      
      bubbleSize = _lerp(52, 26, t);
      fontSize = bubbleSize / 2;
      qPadding = _lerp(7, 3.5, t);
      topBarScale = _lerp(2.5, 1.6, t);
    } else if (qNum <= 70) {
      maxQuestionsPerColumn = (qNum <= 40) ? 20 : (qNum / 2).ceil();
      final t = ((qNum - 20) / (70 - 20)).clamp(0.0, 1.0);

      bubbleSize = _lerp(26, 16, t);
      fontSize = bubbleSize / 2;
      qPadding = _lerp(3.5, 2, t);
      topBarScale = _lerp(1.6, 1, t);
    }

    final List<List<int>> columnsData = [];
    for (var i = 0; i < qNum; i += maxQuestionsPerColumn) {
      final end = (i + maxQuestionsPerColumn < qNum) ? i + maxQuestionsPerColumn : qNum;
      columnsData.add(List<int>.generate(end - i, (index) => i + index + 1));
    }

    final List<Rect> numberROIs = [];
    final List<Rect> optionROIs = [];
    final Map<int, List<Rect>> answerKeyROIs = {};

    List<Rect>? numberRoisSource;
    List<Rect>? optionRoisSource;
    final Map<int, List<Rect>> answerKeyRoisSources = {};

    pw.Widget numberWidget = pw.SizedBox.shrink();
    if (nAmt > 0) {
      final (widget, rois) = _buildNumberBox(topBarScale, nAmt, nTtl);
      
      numberWidget = widget;
      numberRoisSource = rois;
    }

    pw.Widget optionWidget = pw.SizedBox.shrink();
    if (opts.isNotEmpty) {
      final double contentWidth =
          PdfPageFormat.a4.width - 48.0 - 2 * _anchorSize;
      final double numberBoxWidth = nAmt > 0
          ? math.max(
              nAmt * 20.0 * topBarScale,
              nTtl.length * 8.0 * topBarScale * 0.6,
            )
          : 0.0;
      final double optionMaxWidth =
          math.max(120.0, contentWidth - numberBoxWidth - 12.0);
      final (widget, rois) = _buildOptionBox(
        topBarScale,
        opts,
        oTtl,
        maxWidth: optionMaxWidth,
      );

      optionWidget = widget;
      optionRoisSource = rois;
    }

    pw.Widget answerKeyWidget = pw.Expanded(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < columnsData.length; i++) ...[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: columnsData[i].map((qNum) {
                  final (widget, rois) = _createQuestionLine(qNum, letters, bubbleSize, fontSize, qPadding);
                  
                  answerKeyRoisSources[qNum] = rois;
                  return widget;
                }).toList(),
              ),
            ),
          ]
        ],
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned(top: 0, left: 0, child: _createAnchorMarker()),
              pw.Positioned(top: 0, right: 0, child: _createAnchorMarker()),
              pw.Positioned(bottom: 0, left: 0, child: _createAnchorMarker()),
              pw.Positioned(bottom: 0, right: 0, child: _createAnchorMarker()),

              pw.Padding(
                padding: const pw.EdgeInsets.all(_anchorSize),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (nAmt > 0 || opts.isNotEmpty)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [numberWidget, optionWidget],
                      ),
                    pw.SizedBox(height: 6.0),

                    answerKeyWidget,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();

    if (numberRoisSource != null) numberROIs.addAll(numberRoisSource);
    if (optionRoisSource != null) optionROIs.addAll(optionRoisSource);
    answerKeyRoisSources.forEach((qNum, rois) => answerKeyROIs[qNum] = List<Rect>.from(rois));

    return (pdfBytes: bytes, numberROIs: numberROIs, optionROIs: optionROIs, questionROIs: answerKeyROIs);
  }

  static Future<Uint8List> generatePngBytes(int qNum, int lNum, {String nTtl = "", int nAmt = 0, String oTtl = "", List<String> opts = const []}) async {
    final pdfBytes = (await generateAnswerKeyData(qNum, lNum, nTtl: nTtl, nAmt: nAmt, oTtl: oTtl, opts: opts)).pdfBytes;

    final images = Printing.raster(pdfBytes, pages: [0], dpi: 300);
    await for (final page in images) {
      final pngBytes = await page.toPng();
      return pngBytes;
    }

    throw Exception("Falha ao rasterizar o gabarito para PNG");
  }

  static Future<void> exportAnswerKey(String name, int qNum, int lNum, {String nTtl = "", int nAmt = 0, String oTtl = "", List<String> opts = const [], required bool inPng}) async {
    final Uint8List bytes = inPng
        ? await generatePngBytes(qNum, lNum, nTtl: nTtl, nAmt: nAmt, oTtl: oTtl, opts: opts)
        : (await generateAnswerKeyData(qNum, lNum, nTtl: nTtl, nAmt: nAmt, oTtl: oTtl, opts: opts)).pdfBytes;

    final String extension = inPng ? 'png' : 'pdf';
    final String mimeType = inPng ? 'image/png' : 'application/pdf';

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                    defaultTargetPlatform == TargetPlatform.macOS || 
                    defaultTargetPlatform == TargetPlatform.linux)) {
      
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'Document',
        extensions: [extension],
      );
      
      final FileSaveLocation? result = await getSaveLocation(
        acceptedTypeGroups: [typeGroup],
        suggestedName: '$name.$extension',
      );

      if (result != null) {
        final file = XFile.fromData(bytes, mimeType: mimeType, name: '$name.$extension');
        await file.saveTo(result.path);
      }
      return;
    }

    await Printing.sharePdf(
      bytes: bytes,
      filename: '$name.$extension',
    );
  }

  static pw.Widget _createAnchorMarker() => pw.Container(width: _anchorSize, height: _anchorSize, color: PdfColors.black);

  static List<String> _optNumToLetterList(int lAmt) => List.generate(lAmt, ((index) => String.fromCharCode(65 + index)));

  static (pw.Widget, List<Rect>) _createQuestionLine(int qNum, List<String> opts, double bubbleSize, double fontSize, double qPadding) {
    List<Rect> lineROIs = [];
    
    pw.Widget lineWidget = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: fontSize * 2.5,
          child: pw.Text(
            qNum.toString().padLeft(2, '0'),
            style: pw.TextStyle(fontSize: fontSize * 1.25, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: opts.map(
            (letter) => pw.Padding(
              padding: pw.EdgeInsets.all(qPadding),
              child: pw.CustomPaint(
                size: PdfPoint(bubbleSize, bubbleSize),
                painter: (canvas, size) {
                  final translation = canvas.getTransform().getTranslation();
                  lineROIs.add(Rect.fromLTWH(translation.x, defaultA4Page.height - (translation.y + bubbleSize), bubbleSize, bubbleSize));
                },
                child: pw.Container(
                  width: bubbleSize,
                  height: bubbleSize,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      letter,
                      style: pw.TextStyle(
                        fontSize: fontSize,
                        fontWeight: pw.FontWeight.normal,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );

    return (lineWidget, lineROIs);
  }

  static (pw.Widget, List<Rect>) _buildNumberBox(double scale, int amount, String title) {
    final double boxSize = 20.0 * scale;
    List<Rect> numberROIs = [];

    pw.Widget numberBox = pw.Container(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8.0 * scale, fontWeight: pw.FontWeight.bold)),
          pw.Row(
            children: [
              ...List.generate(amount, (index) =>  pw.CustomPaint(
                size: PdfPoint(boxSize, boxSize),
                painter: (canvas, size) {
                  final translation = canvas.getTransform().getTranslation();
                  numberROIs.add(Rect.fromLTWH(translation.x, defaultA4Page.height - (translation.y + boxSize), boxSize, boxSize));
                },
                child: pw.Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: pw.BoxDecoration(border: pw.Border.all())
                ),
              ))
            ]
          )
        ],
      ),
    );

    return (numberBox, numberROIs);
  }

  static (pw.Widget, List<Rect>) _buildOptionBox(
    double scale,
    List<String> opts,
    String title, {
    double maxWidth = double.infinity,
  }) {
    List<String> labels = opts;
    if (maxWidth.isFinite) {
      final fitted = _fitOptionLabels(opts, scale, maxWidth);
      labels = fitted.labels;
      scale = fitted.scale;
    }

    final double boxSize = 15.0 * scale;
    final double fontSize = 9.0 * scale;

    List<Rect> optionROIs = [];

    pw.Widget optionBox = pw.Container(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8.0 * scale, fontWeight: pw.FontWeight.bold)),
          pw.Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 3.0 * scale),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.CustomPaint(
                        size: PdfPoint(boxSize, boxSize),
                        painter: (canvas, size) {
                          final translation = canvas.getTransform().getTranslation();
                          optionROIs.add(Rect.fromLTWH(translation.x, defaultA4Page.height - (translation.y + boxSize), boxSize, boxSize));
                        },
                        child: pw.Container(
                          width: boxSize,
                          height: boxSize,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: PdfColors.black),
                          ),
                        ),
                      ),

                      pw.SizedBox(width: 2.0 * scale),
                      pw.Text(
                        labels[i],
                        style: pw.TextStyle(
                          fontSize: fontSize,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ]
          )
        ],
      ),
    );

    return (optionBox, optionROIs);
  }

  static double _estimateTextWidth(String text, double fontSize) =>
      text.length * fontSize * 0.62;

  static List<String> _abbreviateLabels(
    List<String> opts, {
    int keepMax = 5,
    int minPrefix = 3,
  }) {
    final abbreviator = _SmartAbbreviator(keepMax: keepMax, minPrefix: minPrefix);
    return opts.map((label) {
      final tokens = label.trim().split(RegExp(r'\s+'));
      final result = <String>[];
      for (final token in tokens) {
        if (token.isEmpty) continue;
        result.add(abbreviator.abbreviateToken(token));
      }
      return result.isEmpty ? label.trim() : result.join(' ');
    }).toList();
  }

  static double _optionRowWidth(List<String> labels, double scale) {
    final double perOption = 15.0 * scale + 8.0 * scale;
    return labels.fold(
      0.0,
      (width, label) =>
          width + perOption + _estimateTextWidth(label, 9.0 * scale),
    );
  }

  static ({List<String> labels, double scale}) _fitOptionLabels(
    List<String> opts,
    double scale,
    double maxWidth,
  ) {
    if (_optionRowWidth(opts, scale) <= maxWidth) {
      return (labels: opts, scale: scale);
    }

    final labels = _abbreviateLabels(opts);
    final shrunk = _largestFittingScale(labels, scale, maxWidth, 0.7);
    if (shrunk != null) {
      return (labels: labels, scale: shrunk);
    }

    final shorter = _abbreviateLabels(opts, keepMax: 3, minPrefix: 2);
    final shrunkMore = _largestFittingScale(shorter, scale, maxWidth, 0.6);
    return (labels: shorter, scale: shrunkMore ?? 0.6);
  }

  static double? _largestFittingScale(
    List<String> labels,
    double scale,
    double maxWidth,
    double minScale,
  ) {
    var candidate = scale;
    while (candidate >= minScale) {
      if (_optionRowWidth(labels, candidate) <= maxWidth) return candidate;
      candidate -= 0.05;
    }
    return null;
  }
}

class _SmartAbbreviator {
  final int keepMax;
  final int minPrefix;
  final Set<String> _used = {};

  static const Map<String, String> _specialRoots = {
    'edific': 'Edf.',
    'enferm': 'Enf.',
  };

  _SmartAbbreviator({this.keepMax = 5, this.minPrefix = 3});

  static final RegExp _hasDigit = RegExp(r'[0-9]');

  String abbreviateToken(String token) {
    var clean = token;
    while (clean.endsWith('.')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (clean.isEmpty) return token;
    if (_hasDigit.hasMatch(clean) || clean.length <= keepMax) return clean;

    final lower = clean.toLowerCase();
    for (final entry in _specialRoots.entries) {
      if (lower.startsWith(entry.key) &&
          !_used.contains(entry.value.toLowerCase())) {
        _used.add(entry.value.toLowerCase());
        return entry.value;
      }
    }

    for (var len = minPrefix; len < clean.length; len++) {
      final candidate = '${clean.substring(0, len)}.';
      if (!_used.contains(candidate.toLowerCase())) {
        _used.add(candidate.toLowerCase());
        return candidate;
      }
    }
    return clean;
  }
}