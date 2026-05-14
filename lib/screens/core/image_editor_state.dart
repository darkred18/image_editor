import 'dart:convert';
import 'dart:math' as math;
// import 'package:vector_math/vector_math_64.dart'
//     show Vector3; // Vector3를 위한 추가 임포트
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/models/painting_data_model.dart';
import 'package:image_editor/screens/edit_screen.dart';

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
  double minScale = 1.0; // 추가

  Size viewportSize = Size.zero;

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
  EditorTab tabIndex = EditorTab.crop;

  void setTabIndex(EditorTab v) {
    tabIndex = v;
    notifyListeners();
  }

  //----------------------------------
  // 편집 모드
  //----------------------------------
  bool isAnalysisMode = false;

  void setAnalysisMode(bool v) {
    isAnalysisMode = v;
    if (v) tabIndex = EditorTab.crop;
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

  void updateLayout(Size size) {
    viewportSize = size;
    _lastSize = size; // 👈 이 줄을 추가하여 ROI 업데이트 시 체크를 통과하게 합니다.
    // 1. 이미지 비율과 화면 비율 계산
    double aspectRatio = imgW / imgH;
    double viewRatio = size.width / size.height;

    // 2. 화면에 꽉 채우기 위한 Scale 계산 (BoxFit.contain과 유사한 원리)
    double scale;
    if (aspectRatio > viewRatio) {
      // 이미지가 더 가로로 긴 경우 -> 너비 기준
      scale = size.width / imgW;
    } else {
      // 이미지가 더 세로로 긴 경우 -> 높이 기준
      scale = size.height / imgH;
    }

    drawW = imgW.toDouble();
    drawH = imgH.toDouble();

    // 3. 초기 Matrix 설정 (Alignment.topLeft 기준이므로 꽉 차게 보이도록 스케일 적용)
    // 만약 중앙 정렬을 원하시면 translation 값도 추가해야 하지만,
    // 현재 CanvasCore가 topLeft 기준이므로 scale만 주어도 꽉 차게 시작합니다.

    // scale 계산 후 minScale도 저장
    minScale = scale; // 추가

    controller.value = Matrix4.diagonal3Values(scale, scale, 1.0);

    notifyListeners();
  }

  //----------------------------------
  void updateRoi(Offset newPos) {
    if (_lastSize == null) return;

    roiPosition = Offset(
      newPos.dx.clamp(0.0, _lastSize!.width - roiSize),

      newPos.dy.clamp(0.0, _lastSize!.height - roiSize),
    );
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
    if (!isImageReady || drawW <= 0 || drawH <= 0 || imgW == 0 || imgH == 0)
      return;

    try {
      // 1. 현재 InteractiveViewer의 변환 상태(Matrix) 가져오기
      final matrix = controller.value;
      final double scale = matrix.getMaxScaleOnAxis();

      // ROI 화면 좌표
      final roiCenter = Offset(
        roiPosition.dx + (roiSize / 2),
        roiPosition.dy + (roiSize / 2),
      );

      // 역행렬
      final inverseMatrix = Matrix4.inverted(matrix);

      // 이미지 로컬 좌표
      final localPoint = MatrixUtils.transformPoint(inverseMatrix, roiCenter);

      final double localX = localPoint.dx;
      final double localY = localPoint.dy;

      // 원본 이미지 픽셀 변환
      final px = (localX / drawW * imgW).toInt();
      final py = (localY / drawH * imgH).toInt();

      // 5. 줌 배율을 고려한 크롭 사이즈 (화면에서 보이는 크기만큼 픽셀로 환산)
      final double pixelRoiSize = (roiSize / scale) * (imgW / drawW);
      final pw = pixelRoiSize.toInt().clamp(1, imgW);
      final ph = pixelRoiSize.toInt().clamp(1, imgH);

      // 6. 경계값 계산 및 크롭
      final cutX = (px - pw ~/ 2).clamp(0, imgW - pw);
      final cutY = (py - ph ~/ 2).clamp(0, imgH - ph);

      // 6. OpenCV 영역 추출 및 업데이트
      final cropped = srcMat.region(cv.Rect(cutX, cutY, pw, ph)).clone();
      if (!cropped.isEmpty) {
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
