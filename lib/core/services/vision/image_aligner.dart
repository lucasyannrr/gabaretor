import 'dart:math' as math;

import 'package:dartcv4/dartcv.dart' as cv;

class MarkerRect {
  final int x;
  final int y;
  final int width;
  final int height;

  const MarkerRect(this.x, this.y, this.width, this.height);
}

class ImageAligner {
  final int targetWidth;
  final int targetHeight;

  static const double pageMarginPt = 24.0;
  static const double anchorSizePt = 26.0;
  static const double pageWidthPt = 595.28;
  static const double pageHeightPt = 841.89;

  ImageAligner({this.targetWidth = 1000, this.targetHeight = 1414});

  static List<MarkerRect> detectMarkers(
    cv.Mat gray, {
    int minArea = 40,
    int maxArea = 3000,
    double minAspect = 0.6,
    double maxAspect = 1.7,
    double minExtent = 0.82,
    int blockSize = 51,
    double c = 15,
  }) {
    final thresh = cv.adaptiveThreshold(
      gray,
      255,
      cv.ADAPTIVE_THRESH_GAUSSIAN_C,
      cv.THRESH_BINARY_INV,
      blockSize,
      c,
    );

    final (contours, hierarchy) = cv.findContours(
      thresh,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );

    final result = <MarkerRect>[];
    final data = thresh.data;
    final cols = thresh.cols;
    final rows = thresh.rows;

    bool solidCenter(cv.Rect b) {
      if (b.width <= 0 || b.height <= 0) return false;
      final x0 = b.x + b.width * 0.3;
      final y0 = b.y + b.height * 0.3;
      final spanX = b.width * 0.4;
      final spanY = b.height * 0.4;
      var fg = 0;
      var total = 0;
      for (var iy = 0; iy < 5; iy++) {
        for (var ix = 0; ix < 5; ix++) {
          final px = (x0 + spanX * ix / 4).round();
          final py = (y0 + spanY * iy / 4).round();
          if (px < 0 || py < 0 || px >= cols || py >= rows) continue;
          total++;
          if (data[py * cols + px] != 0) fg++;
        }
      }
      return total > 0 && fg >= total * 0.8;
    }

    for (int i = 0; i < contours.length; i++) {
      final contour = contours[i];
      final area = cv.contourArea(contour);
      if (area < minArea || area > maxArea) continue;

      final peri = cv.arcLength(contour, true);
      final approx = cv.approxPolyDP(contour, 0.04 * peri, true);
      final isQuad = approx.length == 4 && cv.isContourConvex(approx);
      if (!isQuad) {
        approx.dispose();
        continue;
      }

      final rr = cv.minAreaRect(approx);
      final double shortSide = math.min(rr.size.width, rr.size.height);
      final double longSide = math.max(rr.size.width, rr.size.height);
      final double rectArea = rr.size.width * rr.size.height;
      rr.dispose();

      final bounding = cv.boundingRect(approx);
      approx.dispose();

      if (shortSide <= 0 || rectArea <= 0) {
        bounding.dispose();
        continue;
      }
      final aspect = longSide / shortSide;
      final extent = area / rectArea;
      if (aspect < minAspect || aspect > maxAspect) {
        bounding.dispose();
        continue;
      }
      if (extent < minExtent) {
        bounding.dispose();
        continue;
      }
      if (!solidCenter(bounding)) {
        bounding.dispose();
        continue;
      }

      result.add(MarkerRect(bounding.x, bounding.y, bounding.width, bounding.height));
      bounding.dispose();
    }

    thresh.dispose();
    hierarchy.dispose();
    contours.dispose();
    return result;
  }

  cv.Mat align(cv.Mat sourceImg) {
    final bool ownGray = sourceImg.channels != 1;
    final cv.Mat grayFull =
        ownGray ? cv.cvtColor(sourceImg, cv.COLOR_BGR2GRAY) : sourceImg;

    var working = grayFull;
    var ownWorking = false;
    double scale = 1.0;
    const double workWidth = 1000;
    if (grayFull.cols > workWidth) {
      scale = grayFull.cols / workWidth;
      working = cv.resize(
        grayFull,
        ((grayFull.cols / scale).round(), (grayFull.rows / scale).round()),
      );
      ownWorking = true;
    }

    final int imgCols = grayFull.cols;
    final int imgRows = grayFull.rows;

    final side = 0.027 * working.cols;
    var detected = detectMarkers(
      working,
      minArea: (0.15 * side * side).round(),
      maxArea: (8.0 * side * side).round(),
    );
    if (detected.length < 4) {
      detected = detectMarkers(
        working,
        minArea: (0.1 * side * side).round(),
        maxArea: (12.0 * side * side).round(),
        minAspect: 0.5,
        maxAspect: 2.0,
        minExtent: 0.6,
        blockSize: 31,
        c: 10,
      );
    }
    final markers = _filterBySize(detected);

    if (ownWorking) working.dispose();
    if (ownGray) grayFull.dispose();

    if (markers.length < 4) {
      throw Exception(
        "Alinhamento Impossível: O OpenCV encontrou apenas ${markers.length} marcadores. O sistema precisa de pelo menos 4."
      );
    }

    final centers = markers
        .map(
          (m) => cv.Point(
            (m.x + m.width / 2).toInt(),
            (m.y + m.height / 2).toInt(),
          ),
        )
        .toList();

    final sortedPoints = _findExtremeCorners(centers);

    final double quadArea = _polygonArea(sortedPoints);
    final double workArea = (imgCols / scale) * (imgRows / scale);
    if (quadArea < 0.05 * workArea) {
      throw Exception(
        "Alinhamento Impossível: as âncoras encontradas não cercam a folha inteira. Aproxime o gabarito e mantenha os 4 cantos visíveis."
      );
    }

    final double anchorInsetPt = pageMarginPt + anchorSizePt / 2;
    final double scaleX = targetWidth / pageWidthPt;
    final double scaleY = targetHeight / pageHeightPt;

    final destinationPoints = [
      cv.Point2f(anchorInsetPt * scaleX, anchorInsetPt * scaleY),
      cv.Point2f((pageWidthPt - anchorInsetPt) * scaleX, anchorInsetPt * scaleY),
      cv.Point2f((pageWidthPt - anchorInsetPt) * scaleX, (pageHeightPt - anchorInsetPt) * scaleY),
      cv.Point2f(anchorInsetPt * scaleX, (pageHeightPt - anchorInsetPt) * scaleY),
    ];

    final srcPts = cv.VecPoint2f.fromList(sortedPoints
        .map((p) => cv.Point2f(p.x * scale, p.y * scale))
        .toList());
    final dstPts = cv.VecPoint2f.fromList(destinationPoints);

    try {
      final M = cv.getPerspectiveTransform2f(srcPts, dstPts);
      final alignedImg = cv.warpPerspective(sourceImg, M, (targetWidth, targetHeight));
      
      M.dispose();
      return alignedImg;
    } finally {
      srcPts.dispose();
      dstPts.dispose();
    }
  }

  static List<MarkerRect> _filterBySize(List<MarkerRect> markers) {
    if (markers.length < 4) return markers;
    final sides = markers.map((m) => (m.width + m.height) / 2).toList()..sort();
    final median = sides[sides.length ~/ 2];
    if (median <= 0) return markers;
    final kept = markers.where((m) {
      final s = (m.width + m.height) / 2;
      return s >= 0.5 * median && s <= 1.8 * median;
    }).toList();
    return kept.isNotEmpty ? kept : markers;
  }

  static double _polygonArea(List<cv.Point> pts) {
    if (pts.length < 3) return 0;
    var area = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      area += a.x * b.y - b.x * a.y;
    }
    return area.abs() / 2;
  }

  List<cv.Point> _findExtremeCorners(List<cv.Point> pts) {
    cv.Point topLeft = pts[0];
    cv.Point topRight = pts[0];
    cv.Point bottomRight = pts[0];
    cv.Point bottomLeft = pts[0];

    int minSum = pts[0].x + pts[0].y;
    int maxSum = pts[0].x + pts[0].y;
    int minDiff = pts[0].y - pts[0].x;
    int maxDiff = pts[0].y - pts[0].x;

    for (var p in pts) {
      int sum = p.x + p.y;
      int diff = p.y - p.x;

      if (sum < minSum) {
        minSum = sum;
        topLeft = p;
      }
      if (sum > maxSum) {
        maxSum = sum;
        bottomRight = p;
      }
      if (diff < minDiff) {
        minDiff = diff;
        topRight = p;
      }
      if (diff > maxDiff) {
        maxDiff = diff;
        bottomLeft = p;
      }
    }

    return [topLeft, topRight, bottomRight, bottomLeft];
  }
}