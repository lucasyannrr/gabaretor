import 'dart:math' as math;

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart' as tf;

class OcrResult {
  final int number;
  final double confidence;

  OcrResult({required this.number, required this.confidence});
}

class OcrDetector {
  final double thresholdConfidence;

  static tf.Interpreter? _interpreter;
  static bool _isInitialized = false;

  OcrDetector({this.thresholdConfidence = 55.0});

  static Future<void> init() async {
    if (_isInitialized && _interpreter != null) return;
    try {
      final bytes = await loadModelBytes();
      initFromBytes(bytes);
    } catch (e) {
      rethrow;
    }
  }

  static Uint8List? _modelCache;

  static Future<Uint8List> loadModelBytes() async {
    if (_modelCache != null) return _modelCache!;
    final ByteData data = await rootBundle.load('assets/mnist_digits.tflite');
    final bytes = data.buffer.asUint8List();
    _modelCache = bytes;
    return bytes;
  }

  static void initFromBytes(Uint8List bytes) {
    if (_isInitialized && _interpreter != null) return;
    _interpreter = tf.Interpreter.fromBuffer(bytes);
    _isInitialized = true;
  }

  List<List<List<List<double>>>> roiToSingleChannelList({
    required cv.Mat alignedGrayImg,
    required List<Rect> rects,
  }) {
    List<List<List<double>>> processSingleRoi(Rect uiRect) {
      final pad = (math.min(uiRect.width, uiRect.height) * 0.18).round();
      final roi = cv.Rect(
        uiRect.left.toInt() + pad,
        uiRect.top.toInt() + pad,
        (uiRect.width.toInt() - pad * 2).clamp(1, 10000),
        (uiRect.height.toInt() - pad * 2).clamp(1, 10000),
      );

      final cropped = alignedGrayImg.region(roi);

      final mean = cv.mean(cropped).val1;
      final threshold = (mean < 140.0 ? 128.0 : mean * 0.85).clamp(1.0, 254.0);
      final thresholded = cv.threshold(
        cropped,
        threshold,
        255,
        cv.THRESH_BINARY_INV,
      ).$2;

      final (contours, hierarchy) = cv.findContours(
        thresholded,
        cv.RETR_EXTERNAL,
        cv.CHAIN_APPROX_SIMPLE,
      );
      var bboxW = 0;
      var bboxH = 0;
      var bboxX = 0;
      var bboxY = 0;
      var bestArea = 0.0;
      for (var i = 0; i < contours.length; i++) {
        final area = cv.contourArea(contours[i]);
        if (area > bestArea) {
          bestArea = area;
          final r = cv.boundingRect(contours[i]);
          bboxX = r.x;
          bboxY = r.y;
          bboxW = r.width;
          bboxH = r.height;
          r.dispose();
        }
      }
      contours.dispose();
      hierarchy.dispose();

      final canvas = cv.Mat.create(
        rows: 28,
        cols: 28,
        type: cv.MatType.CV_8UC1,
      );
      canvas.setTo(cv.Scalar(0));

      if (bboxW > 1 && bboxH > 1) {
        final digit = thresholded.region(cv.Rect(bboxX, bboxY, bboxW, bboxH));
        final longest = bboxW > bboxH ? bboxW : bboxH;
        final scale = 20.0 / longest;
        final targetW = (bboxW * scale).round().clamp(1, 20);
        final targetH = (bboxH * scale).round().clamp(1, 20);
        final scaled = cv.resize(
          digit,
          (targetW, targetH),
          interpolation: cv.INTER_AREA,
        );

        final scaledData = scaled.data;
        var sumX = 0.0;
        var sumY = 0.0;
        var mass = 0.0;
        for (var y = 0; y < targetH; y++) {
          for (var x = 0; x < targetW; x++) {
            final w = scaledData[y * targetW + x] / 255.0;
            sumX += x * w;
            sumY += y * w;
            mass += w;
          }
        }

        var offsetX = (28 - targetW) ~/ 2;
        var offsetY = (28 - targetH) ~/ 2;
        if (mass > 0) {
          final centerX = sumX / mass;
          final centerY = sumY / mass;
          offsetX = (14.0 - centerX).round().clamp(0, 28 - targetW);
          offsetY = (14.0 - centerY).round().clamp(0, 28 - targetH);
        }

        final dest = cv.Rect(offsetX, offsetY, targetW, targetH);
        final destView = canvas.region(dest);
        scaled.copyTo(destView);
        destView.dispose();

        digit.dispose();
        scaled.dispose();
      }

      final u8Data = canvas.data;
      List<List<List<double>>> tensor3d = List.generate(28, (y) {
        return List.generate(28, (x) {
          int index = (y * 28) + x;
          double v = u8Data[index] / 255.0;
          return [v];
        });
      });

      cropped.dispose();
      thresholded.dispose();
      canvas.dispose();

      return tensor3d;
    }

    return rects.map((rect) => processSingleRoi(rect)).toList();
  }

  List<OcrResult> detectNumbers({required List<List<List<List<double>>>> digitBoxes}) {
    if (!_isInitialized || _interpreter == null) {
      throw Exception("OcrDetector não foi inicializado. Chame initialize() primeiro.");
    }

    final results = <OcrResult>[];

    for (var box in digitBoxes) {
      var input = [box];
      var output = List.generate(1, (_) => List<double>.filled(10, 0.0));

      _interpreter!.run(input, output);

      List<double> probabilities = List<double>.from(output[0]);

      int predictedDigit = -1;
      double highestConfidence = -1.0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > highestConfidence) {
          highestConfidence = probabilities[i];
          predictedDigit = i;
        }
      }

      double confidencePercentage = highestConfidence * 100.0;

      if (confidencePercentage >= thresholdConfidence) {
        results.add(OcrResult(number: predictedDigit, confidence: confidencePercentage));
      } else {
        results.add(OcrResult(number: -1, confidence: confidencePercentage));
      }
    }

    return results;
  }
}