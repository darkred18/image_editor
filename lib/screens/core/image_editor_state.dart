import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/models/painting_data_model.dart';

class ImageEditorState extends ChangeNotifier {
  //----------------------------------
  // 이미지
  //----------------------------------
  final Uint8List imageBytes;

  late final cv.Mat srcMat;
  bool isMatReady = false;

  late final int imgW;
  late final int imgH;

  //----------------------------------
  // 뷰 (줌/팬)
  //----------------------------------
  final TransformationController controller = TransformationController();

  //----------------------------------
  // ROI (화면 좌표 기준)
  //----------------------------------
  Offset roiPosition = const Offset(150, 250);
  double roiSize = 30;

  //----------------------------------
  // Layout 정보
  //----------------------------------
  double drawW = 0;
  double drawH = 0;

  double imageOffsetX = 0;
  double imageOffsetY = 0;

  //----------------------------------
  // 결과 데이터
  //----------------------------------
  Uint8List? croppedPreview;
  Color extractedColor = Colors.white;

  List<Color> dominantColors = [];
  List<PaintColorModel> paintDB = [];
  List<PaintColorModel> recommendedPaints = [];

  MixResultModel2? bestMix;

  //----------------------------------
  ImageEditorState(this.imageBytes) {
    _init();
  }

  //----------------------------------
  Future<void> _init() async {
    srcMat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);

    imgW = srcMat.cols;
    imgH = srcMat.rows;

    await _loadPaintDB();

    notifyListeners();
  }

  //----------------------------------
  Future<void> _loadPaintDB() async {
    final jsonString = await rootBundle.loadString('assets/paint_db.json');

    final List data = jsonDecode(jsonString);

    paintDB = data.map((e) => PaintColorModel.fromJson(e)).toList();
  }

  //----------------------------------
  void updateLayout(Size size) {
    final containerAspect = size.width / size.height;

    final imageAspect = imgW / imgH;

    if (containerAspect > imageAspect) {
      drawH = size.height;
      drawW = drawH * imageAspect;
    } else {
      drawW = size.width;
      drawH = drawW / imageAspect;
    }

    imageOffsetX = (size.width - drawW) / 2;

    imageOffsetY = (size.height - drawH) / 2;

    notifyListeners();
  }

  //----------------------------------
  void updateRoi(Offset pos) {
    roiPosition = pos;
    updateRoiAnalysis();
    notifyListeners();
  }

  //----------------------------------
  double colorDistance(List<double> a, List<double> b) {
    return math.sqrt(
      math.pow(a[0] - b[0] * 0.8, 2) +
          math.pow(a[1] - b[1], 2) +
          math.pow(a[2] - b[2], 2),
    );
  }

  //----------------------------------
  List<PaintColorModel> recommendPaints(List<double> targetLab) {
    final sorted = [...paintDB]
      ..sort(
        (a, b) => colorDistance(
          a.lab,
          targetLab,
        ).compareTo(colorDistance(b.lab, targetLab)),
      );

    return sorted.take(5).toList();
  }

  //----------------------------------
  MixResultModel2 findBestMix(List<double> targetLab) {
    final c = recommendPaints(targetLab);

    final a = c[0];
    final b = c[1];
    final d = c[2];

    MixResultModel2? best;

    for (int i = 0; i <= 100; i += 5) {
      for (int j = 0; j <= 100 - i; j += 5) {
        int k = 100 - i - j;

        final wa = i / 100;
        final wb = j / 100;
        final wc = k / 100;

        final mix = [
          a.lab[0] * wa + b.lab[0] * wb + d.lab[0] * wc,
          a.lab[1] * wa + b.lab[1] * wb + d.lab[1] * wc,
          a.lab[2] * wa + b.lab[2] * wb + d.lab[2] * wc,
        ];

        final dist = colorDistance(targetLab, mix);

        if (best == null || dist < best.distance) {
          best = MixResultModel2(
            paints: [a, b, d],
            weights: [wa, wb, wc],
            distance: dist,
          );
        }
      }
    }

    return best!;
  }

  //----------------------------------
  void updateRoiAnalysis() {
    if (drawW == 0 || drawH == 0) return;

    final matrix = controller.value;

    final roiCenter = Offset(
      roiPosition.dx + roiSize / 2,
      roiPosition.dy + roiSize / 2,
    );

    final inv = Matrix4.inverted(matrix);

    final t = MatrixUtils.transformPoint(inv, roiCenter);

    final imageX = (t.dx - imageOffsetX).clamp(0.0, drawW);

    final imageY = (t.dy - imageOffsetY).clamp(0.0, drawH);

    final px = (imageX / drawW * imgW).toInt();
    final py = (imageY / drawH * imgH).toInt();

    final scale = matrix.getMaxScaleOnAxis();

    final size = (roiSize / scale) * (imgW / drawW);

    final pw = size.toInt().clamp(1, imgW);
    final ph = size.toInt().clamp(1, imgH);

    final cutX = (px - pw ~/ 2).clamp(0, imgW - pw);
    final cutY = (py - ph ~/ 2).clamp(0, imgH - ph);

    final cropped = srcMat.region(cv.Rect(cutX, cutY, pw, ph)).clone();

    final (_, encoded) = cv.imencode(".jpg", cropped);

    final rgbMean = cv.mean(cropped);

    final rgbColor = Color.fromARGB(
      255,
      rgbMean.val[2].round(),
      rgbMean.val[1].round(),
      rgbMean.val[0].round(),
    );

    final labMat = cv.cvtColor(cropped, cv.COLOR_BGR2Lab);

    final labMean = cv.mean(labMat);

    final targetLab = [
      labMean.val[0] * 100 / 255,
      labMean.val[1] - 128,
      labMean.val[2] - 128,
    ];

    croppedPreview = encoded;
    extractedColor = rgbColor;
    recommendedPaints = recommendPaints(targetLab);
    bestMix = findBestMix(targetLab);

    cropped.dispose();
    labMat.dispose();

    notifyListeners();
  }

  //----------------------------------
  void disposeAll() {
    controller.dispose();
    srcMat.dispose();
  }
}
