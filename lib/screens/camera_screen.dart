import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:image_picker/image_picker.dart';
import 'package:gabaretor/core/services/vision/image_aligner.dart';
import 'package:gabaretor/core/services/vision/image_parser.dart';
import 'package:gabaretor/core/storage_manager.dart';
import 'package:gabaretor/core/services/generation/answer_key.dart';
import 'package:gabaretor/main.dart';

import 'camera_result.dart';

class CameraOverlayData {
  final List<MarkerRect> markers;
  final Size frameSize;
  final bool certain;

  const CameraOverlayData(this.markers, this.frameSize, this.certain);
}

class CameraRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const CameraRoundButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class CameraShutterButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CameraShutterButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null ? Colors.white38 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class CameraAnchorOverlayPainter extends CustomPainter {
  final List<MarkerRect> markers;
  final Size frameSize;
  final bool mirrored;
  final bool certain;
  final int quarterTurns;

  const CameraAnchorOverlayPainter({
    required this.markers,
    required this.frameSize,
    required this.mirrored,
    required this.certain,
    this.quarterTurns = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (frameSize.width <= 0 || frameSize.height <= 0) return;

    final frameW = frameSize.width;
    final frameH = frameSize.height;
    final frameLandscape = frameW >= frameH;
    final boxLandscape = size.width >= size.height;

    int turns = quarterTurns;
    if (frameLandscape != boxLandscape && quarterTurns == 0) {
      turns = 1;
    }

    final odd = turns.isOdd;
    final displayWidth = odd ? frameH : frameW;
    final displayHeight = odd ? frameW : frameH;
    final scaleX = size.width / displayWidth;
    final scaleY = size.height / displayHeight;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = certain ? const Color(0xFF00E676) : const Color(0xFFFFC400);

    Offset project(double x, double y) {
      final point = switch (turns) {
        1 => Offset(frameH - y, x),
        2 => Offset(frameW - x, frameH - y),
        3 => Offset(y, frameW - x),
        _ => Offset(x, y),
      };
      final projectedX = mirrored ? displayWidth - point.dx : point.dx;
      return Offset(projectedX * scaleX, point.dy * scaleY);
    }

    for (final marker in markers) {
      final topLeft = project(marker.x.toDouble(), marker.y.toDouble());
      final bottomRight = project(
        (marker.x + marker.width).toDouble(),
        (marker.y + marker.height).toDouble(),
      );
      canvas.drawRect(
        Rect.fromLTRB(
          math.min(topLeft.dx, bottomRight.dx),
          math.min(topLeft.dy, bottomRight.dy),
          math.max(topLeft.dx, bottomRight.dx),
          math.max(topLeft.dy, bottomRight.dy),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CameraAnchorOverlayPainter oldDelegate) =>
      oldDelegate.markers != markers ||
      oldDelegate.frameSize != frameSize ||
      oldDelegate.mirrored != mirrored ||
      oldDelegate.certain != certain ||
      oldDelegate.quarterTurns != quarterTurns;
}

class CameraErrorView extends StatelessWidget {
  final String message;
  final String details;
  final String backLabel;
  final VoidCallback onBack;

  const CameraErrorView({
    super.key,
    required this.message,
    required this.details,
    required this.backLabel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              details,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(backLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final TestModel test;
  const CameraScreen({super.key, required this.camera, required this.test});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final parser = ImageParser();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  List<Rect> numberRois = [];
  List<Rect> optionRois = [];
  Map<int, List<Rect>> questionRois = {};

  late final Future<void> _answerKeyFuture;

  bool _isFlashOn = false;
  bool _flashBusy = false;
  bool _isProcessingFrame = false;
  bool _capturing = false;
  bool _autoTriggered = false;
  int _certainStreak = 0;
  List<Offset> _prevCorners = const [];
  DateTime _lastFrameProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  final ValueNotifier<CameraOverlayData> _overlay =
      ValueNotifier<CameraOverlayData>(
        const CameraOverlayData(<MarkerRect>[], Size.zero, false),
      );

  bool get _mirrorPreview =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  int get _overlayQuarterTurns {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return 0;
    switch (_controller.value.deviceOrientation) {
      case DeviceOrientation.landscapeRight:
        return 1;
      case DeviceOrientation.portraitDown:
        return 2;
      case DeviceOrientation.landscapeLeft:
        return 3;
      case DeviceOrientation.portraitUp:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _answerKeyFuture = _initializeAnswerKey();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      _startStream();
    });
  }

  Future<void> _initializeAnswerKey() async {
    final data = await AnswerKey.generateAnswerKeyData(
      widget.test.tQst,
      widget.test.tLtr,
      nTtl: widget.test.nTtl,
      nAmt: widget.test.nAmt,
      oTtl: widget.test.oTtl,
      opts: widget.test.opts,
    );
    numberRois = data.numberROIs;
    optionRois = data.optionROIs;
    questionRois = data.questionROIs;
  }

  Future<void> _startStream() async {
    try {
      await _controller.startImageStream(_onFrame);
    } catch (_) {}
  }

  void _onFrame(CameraImage image) {
    if (_capturing || _isProcessingFrame || _flashBusy) return;
    final now = DateTime.now();
    if (now.difference(_lastFrameProcessed) <
        const Duration(milliseconds: 200)) {
      return;
    }
    _isProcessingFrame = true;
    _lastFrameProcessed = now;
    try {
      final data = _analyzeFrame(image);
      _overlay.value = data;
      if (data.certain && _cornersStable(data.markers)) {
        _prevCorners = _centers(data.markers);
        _certainStreak++;
        if (_certainStreak >= 3 && !_autoTriggered) {
          _autoTriggered = true;
          _capture();
        }
      } else {
        _certainStreak = 0;
        _autoTriggered = false;
        _prevCorners = const [];
      }
    } catch (_) {
    } finally {
      _isProcessingFrame = false;
    }
  }

  List<Offset> _centers(List<MarkerRect> markers) => markers
      .map((m) => Offset(m.x + m.width / 2, m.y + m.height / 2))
      .toList();

  bool _cornersStable(List<MarkerRect> markers) {
    if (_prevCorners.length != markers.length || markers.isEmpty) return true;
    final current = _centers(markers);
    var maxMove = 0.0;
    for (var i = 0; i < current.length; i++) {
      final d = (current[i] - _prevCorners[i]).distance;
      if (d > maxMove) maxMove = d;
    }
    final size = _overlay.value.frameSize;
    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    final limit = (diag > 0 ? diag : 1000) * 0.03;
    return maxMove <= limit;
  }

  cv.Mat _grayFromCamera(CameraImage image, double scale) {
    final width = (image.width / scale).round();
    final height = (image.height / scale).round();
    final plane = image.planes.first;
    final bytesPerRow = plane.bytesPerRow;
    final src = plane.bytes;
    final group = image.format.group;
    final pixelStride =
        plane.bytesPerPixel ?? (group == ImageFormatGroup.bgra8888 ? 4 : 1);

    if (group == ImageFormatGroup.bgra8888) {
      const bytesPerPixel = 4;
      final bgra = cv.Mat.create(
        rows: height,
        cols: width,
        type: cv.MatType.CV_8UC4,
      );
      final dst = bgra.data;
      final scaleX = image.width / width;
      final scaleY = image.height / height;
      try {
        for (var y = 0; y < height; y++) {
          final sourceY = (y * scaleY).round();
          for (var x = 0; x < width; x++) {
            final sourceX = (x * scaleX).round();
            final sourceOffset = sourceY * bytesPerRow + sourceX * pixelStride;
            final targetOffset = (y * width + x) * bytesPerPixel;
            dst.setRange(
              targetOffset,
              targetOffset + bytesPerPixel,
              src,
              sourceOffset,
            );
          }
        }
        return cv.cvtColor(bgra, cv.COLOR_BGRA2GRAY);
      } finally {
        bgra.dispose();
      }
    }

    final mat = cv.Mat.create(
      rows: height,
      cols: width,
      type: cv.MatType.CV_8UC1,
    );
    final dst = mat.data;
    final scaleX = image.width / width;
    final scaleY = image.height / height;
    try {
      for (var y = 0; y < height; y++) {
        final sourceY = (y * scaleY).round();
        for (var x = 0; x < width; x++) {
          final sourceX = (x * scaleX).round();
          dst[y * width + x] =
              src[sourceY * bytesPerRow + sourceX * pixelStride];
        }
      }
      return mat;
    } catch (_) {
      mat.dispose();
      rethrow;
    }
  }

  List<MarkerRect> _detectAnchors(CameraImage image) {
    final scale = math.max(1.0, image.width / 800);
    final gray = _grayFromCamera(image, scale);
    try {
      final side = 0.027 * gray.cols;
      final markers = ImageAligner.detectMarkers(
        gray,
        minArea: (0.15 * side * side).round(),
        maxArea: (8.0 * side * side).round(),
      );
      final scaleX = image.width / gray.cols;
      final scaleY = image.height / gray.rows;
      return markers
          .map(
            (marker) => MarkerRect(
              (marker.x * scaleX).round(),
              (marker.y * scaleY).round(),
              (marker.width * scaleX).round(),
              (marker.height * scaleY).round(),
            ),
          )
          .toList();
    } finally {
      gray.dispose();
    }
  }

  CameraOverlayData _analyzeFrame(CameraImage image) {
    final size = Size(image.width.toDouble(), image.height.toDouble());
    List<MarkerRect> markers;
    try {
      markers = _detectAnchors(image);
    } catch (_) {
      markers = const <MarkerRect>[];
    }

    final anchors = _pickCornerAnchors(markers, size);
    final certain = anchors.length == 4;
    return CameraOverlayData(
      certain ? anchors : markers.take(12).toList(),
      size,
      certain,
    );
  }

  /// Escolhe, dentre os quadrados detectados, os 4 mais próximos dos cantos da
  /// imagem e valida que têm tamanho parecido e cobrem boa parte do quadro.
  /// Retorna vazio se a folha ainda não estiver inteira e centralizada.
  List<MarkerRect> _pickCornerAnchors(List<MarkerRect> markers, Size size) {
    if (markers.length < 4) return const <MarkerRect>[];

    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    final used = <int>{};
    final chosen = <MarkerRect>[];
    for (final corner in corners) {
      var best = -1;
      var bestDist = double.infinity;
      for (var i = 0; i < markers.length; i++) {
        if (used.contains(i)) continue;
        final m = markers[i];
        final cx = m.x + m.width / 2;
        final cy = m.y + m.height / 2;
        final dist =
            (cx - corner.dx) * (cx - corner.dx) +
            (cy - corner.dy) * (cy - corner.dy);
        if (dist < bestDist) {
          bestDist = dist;
          best = i;
        }
      }
      if (best < 0) return const <MarkerRect>[];
      used.add(best);
      chosen.add(markers[best]);
    }

    var minSide = double.infinity;
    var maxSide = 0.0;
    var minX = chosen.first.x.toDouble();
    var maxX = (chosen.first.x + chosen.first.width).toDouble();
    var minY = chosen.first.y.toDouble();
    var maxY = (chosen.first.y + chosen.first.height).toDouble();

    for (final m in chosen) {
      final side = (m.width + m.height) / 2;
      if (side < minSide) minSide = side;
      if (side > maxSide) maxSide = side;
      minX = minX < m.x ? minX : m.x.toDouble();
      maxX = maxX > m.x + m.width ? maxX : (m.x + m.width).toDouble();
      minY = minY < m.y ? minY : m.y.toDouble();
      maxY = maxY > m.y + m.height ? maxY : (m.y + m.height).toDouble();
    }

    if (minSide <= 0 || maxSide / minSide > 2.2) return const <MarkerRect>[];
    if ((maxX - minX) < 0.5 * size.width || (maxY - minY) < 0.5 * size.height) {
      return const <MarkerRect>[];
    }
    return chosen;
  }

  @override
  void dispose() {
    _overlay.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }

  Future<void> _toggleFlash() async {
    if (_flashBusy) return;
    _flashBusy = true;
    final target = !_isFlashOn;
    if (mounted) setState(() => _isFlashOn = target);
    try {
      await _controller.setFlashMode(
        target ? FlashMode.torch : FlashMode.off,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isFlashOn = !target);
        _showSnack(context.l10n.flashUnavailable);
      }
    } finally {
      _flashBusy = false;
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      _capturing = true;
      if (mounted) setState(() {});
      await _processImage(picked.path);
    } catch (e) {
      if (mounted) _showSnack(context.l10n.readImageError('$e'));
    } finally {
      _capturing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _capture() async {
    if (_capturing) return;
    _capturing = true;
    _autoTriggered = true;
    if (mounted) setState(() {});
    final wasStreaming = _controller.value.isStreamingImages;
    if (wasStreaming) {
      try {
        await _controller.stopImageStream();
      } catch (_) {}
    }
    try {
      final file = await _controller.takePicture();
      await _processImage(file.path);
    } catch (e) {
      if (mounted) _showSnack(context.l10n.captureError('$e'));
    } finally {
      _capturing = false;
      _certainStreak = 0;
      _autoTriggered = false;
      if (mounted) setState(() {});
      if (wasStreaming) await _startStream();
    }
  }

  Future<void> _processImage(String path) async {
    await _answerKeyFuture;
    final output = await parser.executePipeline(
      path,
      numberRois,
      optionRois,
      questionRois,
    );
    final candidate = buildResultCandidate(output, widget.test);
    if (!mounted) return;

    final action = await _showResultDialog(candidate);
    if (!mounted || action == null || action == 'no') return;

    var finalCandidate = candidate;
    if (action == 'edit') {
      final edited = await editResult(context, candidate, widget.test);
      if (edited == null || !mounted) return;
      finalCandidate = edited;
    }

    await saveResult(finalCandidate, widget.test);
  }

  String _resultsText(ResultCandidate candidate) {
    final l10n = context.l10n;
    final link = resolveLink(candidate);
    final test = widget.test;
    final lines = <String>[
      '${l10n.studentNumber}: '
          '${candidate.studId.isEmpty ? l10n.notAvailable : candidate.studId}',
      '${l10n.markedOption}: '
          '${candidate.markOpt.isEmpty ? l10n.notAvailable : candidate.markOpt}',
      '${l10n.scoreLabel}: ${calcScore(candidate.answers, test)}/${test.tQst}',
    ];
    if (link.cls != null) {
      lines.add(l10n.linkedClass(link.cls!.classId));
      lines.add(
        link.studentName != null
            ? l10n.linkedStudent(link.studentName!)
            : l10n.notLinked,
      );
    } else {
      lines.add(l10n.notLinked);
    }
    if (candidate.numberUncertain) {
      lines.add('');
      lines.add(l10n.numberUncertain);
    }

    final answers = StringBuffer();
    for (var q = 0; q < test.tQst; q++) {
      final letter = candidate.answers[q.toString()]?['answer'];
      answers.write(
        '${q + 1}:${letter == null || letter.isEmpty ? '-' : letter}',
      );
      answers.write((q + 1) % 8 == 0 ? '\n' : '   ');
    }
    lines.add('');
    lines.add(answers.toString());
    return lines.join('\n');
  }

  Future<String?> _showResultDialog(ResultCandidate candidate) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.foundResults),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(ctx).colorScheme.outlineVariant,
              ),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _resultsText(candidate),
                style: const TextStyle(fontFamily: 'monospace', height: 1.4),
              ),
            ),
          ),
        ),
        actions: candidate.numberUncertain
            ? [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'edit'),
                  child: Text(ctx.l10n.editValues),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'no'),
                  child: Text(ctx.l10n.no),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'yes'),
                  child: Text(ctx.l10n.yes),
                ),
              ]
            : [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'yes'),
                  child: Text(ctx.l10n.yes),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'no'),
                  child: Text(ctx.l10n.no),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'edit'),
                  child: Text(ctx.l10n.editValues),
                ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return CameraErrorView(
                message: context.l10n.cameraInitError,
                details: '${snapshot.error}',
                backLabel: context.l10n.back,
                onBack: () => Navigator.of(context).maybePop(),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: CameraPreview(
                    _controller,
                    child: ValueListenableBuilder<CameraOverlayData>(
                      valueListenable: _overlay,
                      builder: (context, data, _) => CustomPaint(
                        painter: CameraAnchorOverlayPainter(
                          markers: data.markers,
                          frameSize: data.frameSize,
                          mirrored: _mirrorPreview,
                          certain: data.certain,
                          quarterTurns: _overlayQuarterTurns,
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CameraRoundButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CameraRoundButton(
                          icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          onTap: _toggleFlash,
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: IgnorePointer(
                            child: ValueListenableBuilder<CameraOverlayData>(
                              valueListenable: _overlay,
                              builder: (context, data, _) {
                                final ready = _capturing || data.certain;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ready
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFFC400),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    ready
                                        ? context.l10n.alignedReady
                                        : context.l10n.adjustSheet,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CameraRoundButton(
                                icon: Icons.photo_library,
                                onTap: _capturing ? null : _pickFromGallery,
                              ),
                              const SizedBox(width: 36),
                              CameraShutterButton(
                                onTap: _capturing ? null : _capture,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
