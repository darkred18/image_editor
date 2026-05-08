import 'dart:convert';
import 'dart:math' as math;
// import 'package:vector_math/vector_math_64.dart'
//     show Vector3; // Vector3를 위한 추가 임포트
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/models/painting_data_model.dart';

class ImageEditorState extends ChangeNotifier {
  //----------------------------------
  // 이미지
  //----------------------------------
  bool isImageReady = false;
  late Uint8List imageBytes;

  // late final cv.Mat srcMat;
  cv.Mat? _srcMat;
  cv.Mat get srcMat => _srcMat!; // 외부에서 접근할 때 사용
  bool isMatReady = false;
  bool isMinimumCount = false;

  late int imgW = 0;
  late int imgH = 0;

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
  // 탭 상태 (패널과 오버레이 동기화)
  //----------------------------------
  int tabIndex = 0;

  void setTabIndex(int v) {
    tabIndex = v;
    notifyListeners();
  }

  //----------------------------------
  // 편집 모드
  //----------------------------------
  bool isAnalysisMode = false;

  void setAnalysisMode(bool v) {
    isAnalysisMode = v;
    if (v) tabIndex = 0;
    notifyListeners();
  }

  Uint8List? croppedPreview;
  Color extractedColor = Colors.white;

  List<Color> dominantColors = [];
  List<PaintColorModel> paintDB = [];
  List<PaintColorModel> recommendedPaints = [];

  MixResultModel2? bestMix;

  //----------------------------------
  // 그리드 설정
  //----------------------------------
  int gridDivisions = 4;
  bool gridWidthBase = true;
  bool showGrid = true;
  Color gridColor = Colors.white60;

  //----------------------------------
  // ImageEditorState(this.imageBytes) {
  //   initWithBytes(imageBytes);
  // }

  //----------------------------------
  //----------------------------------
  // 1. 초기화 로직 수정 (imgW, imgH가 확실히 세팅된 후 Ready)
  //----------------------------------
  Future<void> initWithBytes(Uint8List bytes) async {
    try {
      // 1. 기존에 생성된 Mat이 있다면 먼저 해제
      if (_srcMat != null) {
        _srcMat!.dispose();
      }
      imageBytes = bytes;
      final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);

      if (mat.isEmpty) throw Exception("Mat decode failed");

      _srcMat = mat;
      imgW = srcMat.cols;
      imgH = srcMat.rows;

      // 이미지 로드가 완료된 후 DB 로드
      await _loadPaintDB();

      isImageReady = true;

      // 이미 이미지가 로드된 상태에서 레이아웃 정보가 있다면 즉시 계산
      if (_lastSize != null) {
        updateLayout(_lastSize!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing image: $e");
    }
  }

  Size? _lastSize;

  //----------------------------------
  Future<void> _loadPaintDB() async {
    final jsonString = await rootBundle.loadString('assets/paint_db.json');

    final List data = jsonDecode(jsonString);

    paintDB = data.map((e) => PaintColorModel.fromJson(e)).toList();
  }

  //--------------------------------
  // 2. 레이아웃 업데이트 (나누기 0 방지 및 안전장치)
  //----------------------------------
  void updateLayout(Size size) {
    _lastSize = size;
    if (imgW == 0 || imgH == 0 || size.width == 0 || size.height == 0) return;

    final containerAspect = size.width / size.height;
    final imageAspect = imgW / imgH;

    double newDrawW, newDrawH;

    if (containerAspect > imageAspect) {
      newDrawH = size.height;
      newDrawW = newDrawH * imageAspect;
    } else {
      newDrawW = size.width;
      newDrawH = newDrawW / imageAspect;
    }

    // 🎯 오차 범위를 두어 무한 notifyListeners 방지
    if ((drawW - newDrawW).abs() > 0.1 || (drawH - newDrawH).abs() > 0.1) {
      drawW = newDrawW;
      drawH = newDrawH;
      imageOffsetX = (size.width - drawW) / 2;
      imageOffsetY = (size.height - drawH) / 2;

      // 레이아웃이 변하면 줌 상태를 초기화하거나 ROI 위치를 재조정할 수 있음
      notifyListeners();
    }
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
  // 3. ROI 분석 로직 (비정상적인 스케일/오프셋 방어)
  //----------------------------------
  void updateRoiAnalysis() {
    // 0으로 나누기 방지
    if (!isImageReady || drawW <= 0 || drawH <= 0 || imgW == 0 || imgH == 0)
      return;

    try {
      final matrix = controller.value;
      final roiCenter = Offset(
        roiPosition.dx + roiSize / 2,
        roiPosition.dy + roiSize / 2,
      );

      final inv = Matrix4.inverted(matrix);
      final t = MatrixUtils.transformPoint(inv, roiCenter);

      // InteractiveViewer가 Alignment.center이므로
      // 레터박스 offset(imageOffsetX/Y)을 빼서 이미지 내부 좌표로 변환
      final imageX = (t.dx - imageOffsetX).clamp(0.0, drawW);
      final imageY = (t.dy - imageOffsetY).clamp(0.0, drawH);

      // 실제 이미지 픽셀 좌표 계산
      final px = (imageX / drawW * imgW).toInt();
      final py = (imageY / drawH * imgH).toInt();

      double scale = matrix.getMaxScaleOnAxis();
      if (scale <= 0) scale = 1.0;

      // ROI 크기를 이미지 픽셀 단위로 환산
      final size = (roiSize / scale) * (imgW / drawW);
      final pw = size.toInt().clamp(1, imgW);
      final ph = size.toInt().clamp(1, imgH);

      final cutX = (px - pw ~/ 2).clamp(0, imgW - pw);
      final cutY = (py - ph ~/ 2).clamp(0, imgH - ph);

      // OpenCV 작업 영역
      final cropped = srcMat.region(cv.Rect(cutX, cutY, pw, ph)).clone();
      if (cropped.isEmpty) return;

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
    } catch (e) {
      debugPrint("Analysis Error: $e");
    }
  }

  //----------------------------------
  void disposeAll() {
    controller.dispose();
    _srcMat?.dispose(); // null이 아닐 때만 해제
    _srcMat = null;
  }

  //--------------------------------
  // ROI
  //--------------------------------
  void setRoiSize(double v) {
    roiSize = v;
    notifyListeners();
  }

  void setMinimumMode(bool v) {
    isMinimumCount = v;
    notifyListeners();
  }

  //--------------------------------
  // GRID
  //--------------------------------
  void setGridDivisions(int v) {
    gridDivisions = v;
    notifyListeners();
  }

  void setGridWidthBase(bool v) {
    gridWidthBase = v;
    notifyListeners();
  }

  void setShowGrid(bool v) {
    showGrid = v;
    notifyListeners();
  }

  void setGridColor(Color c) {
    gridColor = c;
    notifyListeners();
  }

  // 이미지(drawW×drawH) 로컬 좌표 → 화면(Stack) 좌표
  Offset getScreenPoint(Offset localPoint) {
    final Matrix4 matrix = controller.value;

    final double dx =
        matrix.row0.x * localPoint.dx +
        matrix.row0.y * localPoint.dy +
        matrix.row0.w;
    final double dy =
        matrix.row1.x * localPoint.dx +
        matrix.row1.y * localPoint.dy +
        matrix.row1.w;

    // Alignment.center 기준: 이미지 좌상단이 imageOffset 위치에 있으므로 더함
    return Offset(dx + imageOffsetX, dy + imageOffsetY);
  }

  // ImageEditorState.dart
  void handleZoomChange() {
    // 레이아웃 전체를 다시 계산할 필요 없이,
    // 현재 transformer 매트릭스 값으로 위젯들을 다시 그리라고만 알림
    notifyListeners();
  }
}
