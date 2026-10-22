import 'dart:io';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'image_aligner.dart';
import 'omr_engine.dart';
import 'ocr_engine.dart';

class ParseOutput {
  final List<OcrResult> numbers;
  final List<OmrResult> optMarked;
  final Map<int, List<OmrResult>> marks;

  ParseOutput({required this.numbers, required this.optMarked, required this.marks});
}

class ImageParser {
  Future<ParseOutput> executePipeline(String imagePath, List<Rect> numberRois, List<Rect> optionRois, Map<int, List<Rect>> answerKeyRois) async {
    final modelBytes = await OcrDetector.loadModelBytes();
    return compute(
      _executePipelineIsolate,
      _PipelineArgs(imagePath, numberRois, optionRois, answerKeyRois, modelBytes),
    );
  }

  static Future<ParseOutput> _executePipelineIsolate(_PipelineArgs args) async {
    OcrDetector.initFromBytes(args.modelBytes);
    final cv.Mat srcImg;
    try {
      final bytes = File(args.imagePath).readAsBytesSync();
      srcImg = cv.imdecode(bytes, cv.IMREAD_GRAYSCALE);
    } catch (_) {
      throw Exception("Não foi possível ler o arquivo de imagem em: ${args.imagePath}");
    }
    if (srcImg.isEmpty) {
      throw Exception("Não foi possível decodificar a imagem em: ${args.imagePath}");
    }

    cv.Mat? alignedImg;
    final aligner = ImageAligner();
    final ocr = OcrDetector();
    final omr = OmrDetector();
    try {
      alignedImg = aligner.align(srcImg);
      if (alignedImg.isEmpty) {
        throw Exception("A imagem alinhada gerada pelo ImageAligner ficou vazia.");
      }

      final double scaleX = aligner.targetWidth / PdfPageFormat.a4.width;
      final double scaleY = aligner.targetHeight / PdfPageFormat.a4.height;

      Rect scaleRect(Rect roi) => Rect.fromLTWH(
        roi.left * scaleX,
        roi.top * scaleY,
        roi.width * scaleX,
        roi.height * scaleY,
      );

      final scaledNumberRois = args.numberRois.map(scaleRect).toList();
      final scaledOptionRois = args.optionRois.map(scaleRect).toList();
      final scaledAnswerKeyRois = <int, List<Rect>>{
        for (final entry in args.answerKeyRois.entries)
          entry.key: entry.value.map(scaleRect).toList(),
      };

      final digitBoxesList = ocr.roiToSingleChannelList(
        alignedGrayImg: alignedImg,
        rects: scaledNumberRois,
      );

      final numbers = ocr.detectNumbers(digitBoxes: digitBoxesList);

      final optMarked = omr.detectMarks(alignedImg, scaledOptionRois);

      final Map<int, List<OmrResult>> marksResults = {};
      scaledAnswerKeyRois.forEach((index, lineRois) {
        marksResults[index - 1] = omr.detectMarks(alignedImg!, lineRois);
      });

      return ParseOutput(numbers: numbers, optMarked: optMarked, marks: marksResults);

    } catch (e) {
      throw Exception("Erro durante o processamento do pipeline do Gabarito: $e");
    } finally {
      srcImg.dispose();
      alignedImg?.dispose();
    }
  }
}
class _PipelineArgs {
  final String imagePath;
  final List<Rect> numberRois;
  final List<Rect> optionRois;
  final Map<int, List<Rect>> answerKeyRois;
  final Uint8List modelBytes;
  _PipelineArgs(this.imagePath, this.numberRois, this.optionRois, this.answerKeyRois, this.modelBytes);
}
