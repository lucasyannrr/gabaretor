import 'dart:ui';
import 'package:dartcv4/dartcv.dart' as cv;

class OmrResult {
  final int index;
  final bool isMarked;
  final bool isAmbiguous;
  final double confidence;

  OmrResult({
    required this.index,
    required this.isMarked,
    this.isAmbiguous = false,
    required this.confidence,
  });
}

class OmrDetector {
  final double minInkFraction;
  final double minRowMargin;

  OmrDetector({this.minInkFraction = 0.18, this.minRowMargin = 0.10});

  List<OmrResult> detectMarks(cv.Mat alignedGrayImg, List<Rect> rois) {
    final inkRatios = List<double>.filled(rois.length, 0.0);

    for (int i = 0; i < rois.length; i++) {
      final uiRect = rois[i];
      final roi = cv.Rect(
        uiRect.left.toInt(),
        uiRect.top.toInt(),
        uiRect.width.toInt(),
        uiRect.height.toInt(),
      );

      if (roi.x < 0 ||
          roi.y < 0 ||
          roi.x + roi.width > alignedGrayImg.cols ||
          roi.y + roi.height > alignedGrayImg.rows) {
        continue;
      }

      final innerWidth = (roi.width * 0.6).round();
      final innerHeight = (roi.height * 0.6).round();
      final innerRect = cv.Rect(
        roi.x + (roi.width - innerWidth) ~/ 2,
        roi.y + (roi.height - innerHeight) ~/ 2,
        innerWidth,
        innerHeight,
      );

      final subMat = alignedGrayImg.region(innerRect);
      final meanGray = cv.mean(subMat).val1;
      inkRatios[i] = ((255.0 - meanGray) / 255.0).clamp(0.0, 1.0);

      subMat.dispose();
    }

    final results = List<OmrResult>.generate(
      rois.length,
      (i) => OmrResult(index: i, isMarked: false, confidence: inkRatios[i]),
    );

    int start = 0;
    while (start < rois.length) {
      final rowTop = rois[start].top;
      int end = start;
      while (end < rois.length && (rois[end].top - rowTop).abs() <= 5.0) {
        end++;
      }

      int primary = start;
      double baseline = double.infinity;
      final candidates = <int>[];
      for (int k = start; k < end; k++) {
        if (inkRatios[k] < baseline) baseline = inkRatios[k];
        if (inkRatios[k] > inkRatios[primary]) primary = k;
        if (inkRatios[k] >= minInkFraction) candidates.add(k);
      }

      final rowAmbiguous = candidates.length >= 2;
      if (rowAmbiguous) {
        for (final c in candidates) {
          results[c] = OmrResult(
            index: c,
            isMarked: false,
            isAmbiguous: true,
            confidence: inkRatios[c],
          );
        }
      }

      final primaryInk = inkRatios[primary];
      final relativeInk = primaryInk - baseline;

      if (primaryInk >= minInkFraction && relativeInk >= minRowMargin) {
        results[primary] = OmrResult(
          index: primary,
          isMarked: true,
          isAmbiguous: rowAmbiguous,
          confidence: primaryInk,
        );
      }

      start = end;
    }

    return results;
  }
}
