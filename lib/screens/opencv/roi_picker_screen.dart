import 'dart:convert';
import 'dart:math' as math;
import 'package:dartcv4/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/models/paint_color_model.dart.temp';
import 'package:image_editor/models/painting_data_model.dart';
import 'package:image_editor/screens/core/brute_force.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';
import 'package:image_editor/screens/opencv/image_simplification_service.dart';
import 'package:dartcv4/dartcv.dart' as cv;

class RoiOverlay extends StatelessWidget {
  final ImageEditorState state;

  const RoiOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: state.roiPosition.dx,
      top: state.roiPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final newPos = state.roiPosition + details.delta;

          state.updateRoi(newPos);
        },
        child: Container(
          width: state.roiSize,
          height: state.roiSize,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.cyanAccent, width: 2),
          ),
        ),
      ),
    );
  }
}

class AdvancedRoiPicker extends StatefulWidget {
  final Uint8List imageBytes;
  // final ImageEditorState state;

  const AdvancedRoiPicker({
    super.key,
    required this.imageBytes,
    // required this.state,
  });

  @override
  State<AdvancedRoiPicker> createState() => _AdvancedRoiPickerState();
}

class _AdvancedRoiPickerState extends State<AdvancedRoiPicker> {
  final TransformationController _controller = TransformationController();
  late cv.Mat _srcMat;
  bool _isMatReady = false;
  bool _isMinimumCount = false;

  final double _fixedRoiSize = 40;

  Offset _roiPosition = const Offset(150, 250);

  Uint8List? croppedPreview;
  Color extractedColor = Colors.white;

  late int imgW;
  late int imgH;

  double _drawW = 0;
  double _drawH = 0;

  double _imageOffsetX = 0;
  double _imageOffsetY = 0;

  List<PaintColorModel> paintDB = [];
  List<PaintColorModel> recommendedPaints = [];
  MixResultModel? bestMix;
  List<Color> dominantColors = [];

  @override
  void initState() {
    super.initState();

    // final mat = cv.imdecode(widget.imageBytes, cv.IMREAD_UNCHANGED);

    _srcMat = cv.imdecode(widget.imageBytes, cv.IMREAD_COLOR);

    imgW = _srcMat.cols;
    imgH = _srcMat.rows;

    _isMatReady = true;

    _initImage();
    _loadPaintDB();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRoiInfo();
    });
  }

  Future<void> _initImage() async {
    _srcMat = cv.imdecode(widget.imageBytes, cv.IMREAD_COLOR);

    imgW = _srcMat.cols;
    imgH = _srcMat.rows;

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRoiInfo();
    });
  }

  Future<void> _loadPaintDB() async {
    final jsonString = await rootBundle.loadString('assets/paint_db.json');

    final List data = jsonDecode(jsonString);

    paintDB = data.map((e) => PaintColorModel.fromJson(e)).toList();
  }

  double colorDistance(List<double> a, List<double> b) {
    return math.sqrt(
      math.pow(a[0] - b[0] * 0.8, 2) +
          math.pow(a[1] - b[1], 2) +
          math.pow(a[2] - b[2], 2),
    );
  }

  // 성능 개선 버전
  List<PaintColorModel> recommendPaints(List<double> targetLab) {
    final top = paintDB
      ..sort(
        (a, b) => colorDistance(
          a.lab,
          targetLab,
        ).compareTo(colorDistance(b.lab, targetLab)),
      );

    final candidates = top.take(5).toList();

    if (_isMinimumCount) {
      final mix2 = findBest2Mix(candidates, targetLab);
      final mix3 = findBest3Mix(candidates, targetLab);
      final best = mix2.distance < mix3.distance ? mix2 : mix3;
      return best.paints;
    }
    return candidates;
  }

  Future<void> _updateRoiInfo() async {
    if (_drawW == 0 || _drawH == 0) return;
    try {
      final matrix = _controller.value;

      final roiCenter = Offset(
        _roiPosition.dx + _fixedRoiSize / 2,
        _roiPosition.dy + _fixedRoiSize / 2,
      );

      final localPoint = roiCenter;

      final inverseMatrix = Matrix4.inverted(matrix);

      final transformed = MatrixUtils.transformPoint(inverseMatrix, localPoint);

      final imageX = (transformed.dx - _imageOffsetX).clamp(0.0, _drawW);

      final imageY = (transformed.dy - _imageOffsetY).clamp(0.0, _drawH);

      final px = (imageX / _drawW * imgW).toInt();

      final py = (imageY / _drawH * imgH).toInt();

      final scale = matrix.getMaxScaleOnAxis();

      final roiPixelSize = (_fixedRoiSize / scale) * (imgW / _drawW);

      final pw = roiPixelSize.toInt().clamp(1, imgW);

      final ph = roiPixelSize.toInt().clamp(1, imgH);

      final cutX = (px - pw ~/ 2).clamp(0, imgW - pw);

      final cutY = (py - ph ~/ 2).clamp(0, imgH - ph);

      final cropped = _srcMat.region(cv.Rect(cutX, cutY, pw, ph)).clone();

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
        labMean.val[0] * 100 / 255, // L 정규화
        labMean.val[1] - 128, // a 정규화
        labMean.val[2] - 128, // b 정규화
      ];

      final recommends = recommendPaints(targetLab);
      final mixResult = findBestMix(targetLab, paintDB);

      setState(() {
        croppedPreview = encoded;

        extractedColor = rgbColor;
        recommendedPaints = recommends;
        bestMix = mixResult;
      });

      cropped.dispose();
      labMat.dispose();
    } catch (e) {
      debugPrint("ROI Error: $e");
    }
  }

  MixResultModel findBestMix(
    List<double> targetLab,
    List<PaintColorModel> paints,
  ) {
    final candidates = recommendPaints(targetLab);

    final a = candidates[0];
    final b = candidates[1];
    final c = candidates[2];

    MixResultModel? best;

    for (int i = 0; i <= 100; i += 5) {
      for (int j = 0; j <= 100 - i; j += 5) {
        int k = 100 - i - j;

        final wa = i / 100;
        final wb = j / 100;
        final wc = k / 100;

        final mixedLab = [
          a.lab[0] * wa + b.lab[0] * wb + c.lab[0] * wc,

          a.lab[1] * wa + b.lab[1] * wb + c.lab[1] * wc,

          a.lab[2] * wa + b.lab[2] * wb + c.lab[2] * wc,
        ];

        final dist = colorDistance(targetLab, mixedLab);

        if (best == null || dist < best.distance) {
          best = MixResultModel(
            a: a,
            b: b,
            c: c,
            wa: wa,
            wb: wb,
            wc: wc,
            distance: dist,
          );
        }
      }
    }

    return best!;
  }

  List<Color> extractDominantColors(cv.Mat cropped) {
    final rows = cropped.rows;
    final cols = cropped.cols;

    final samples = <List<double>>[];

    for (int y = 0; y < rows; y += 2) {
      for (int x = 0; x < cols; x += 2) {
        final pixel = cropped.atVec(y, x); // BGR 순서로 반환 (예: [B, G, R])

        final b = pixel[0].toDouble();
        final g = pixel[1].toDouble();
        final r = pixel[2].toDouble();
        samples.add([b, g, r]);
      }
    }

    if (samples.isEmpty) return [];

    final sampleMat = cv.Mat.fromList(
      samples.length,
      3,
      cv.MatType(cv.MatType.CV_32F),
      samples.expand((e) => e).toList(),
    );

    final labels = cv.Mat.empty();
    final centers = cv.Mat.empty();

    cv.kmeans(
      sampleMat,
      3,
      labels,
      (cv.TERM_COUNT, 10, 1.0),
      3,
      cv.KMEANS_PP_CENTERS,
      centers: centers,
    );

    List<Color> result = [];

    for (int i = 0; i < centers.rows; i++) {
      final b = centers.at<double>(i, 0).round();
      final g = centers.at<double>(i, 1).round();
      final r = centers.at<double>(i, 2).round();

      result.add(Color.fromARGB(255, r, g, b));
    }

    sampleMat.dispose();
    labels.dispose();
    centers.dispose();

    return result;
  }

  @override
  void dispose() {
    _controller.dispose();

    if (_isMatReady) {
      _srcMat.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        title: const Text('색상 찾기', style: TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final containerAspect =
                    constraints.maxWidth / constraints.maxHeight;

                final imageAspect = imgW / imgH;

                if (containerAspect > imageAspect) {
                  _drawH = constraints.maxHeight;
                  _drawW = _drawH * imageAspect;
                } else {
                  _drawW = constraints.maxWidth;
                  _drawH = _drawW / imageAspect;
                }

                _imageOffsetX = (constraints.maxWidth - _drawW) / 2;

                _imageOffsetY = (constraints.maxHeight - _drawH) / 2;

                return Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _controller,
                      maxScale: 20,
                      minScale: 1,
                      clipBehavior: Clip.none,
                      onInteractionUpdate: (_) {
                        _updateRoiInfo();
                      },
                      child: Center(
                        child: SizedBox(
                          width: _drawW,
                          height: _drawH,
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    //--------------------------------
                    // draggable ROI
                    //--------------------------------
                    Positioned(
                      left: _roiPosition.dx,
                      top: _roiPosition.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _roiPosition += details.delta;
                          });

                          _updateRoiInfo();
                        },
                        child: Container(
                          width: _fixedRoiSize,
                          height: _fixedRoiSize,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.cyanAccent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        "ROI를 이동하거나 이미지를 확대하세요",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          //--------------------------------
          // Bottom panel
          //--------------------------------
          Container(
            height: 220,
            color: const Color(0xFF111111),
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (croppedPreview != null)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Image.memory(croppedPreview!, fit: BoxFit.fill),
                  ),

                const SizedBox(width: 20),

                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade800,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: extractedColor,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (bestMix != null) ...[
                        const SizedBox(height: 20),

                        const Text(
                          "혼합 비율 추천",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),
                        if (bestMix!.wa > 0)
                          Text(
                            "${bestMix!.a.name} ${(bestMix!.wa * 100).round()}%",
                            style: const TextStyle(color: Colors.white),
                          ),
                        if (bestMix!.wb > 0)
                          Text(
                            "${bestMix!.b.name} ${(bestMix!.wb * 100).round()}%",
                            style: const TextStyle(color: Colors.white),
                          ),
                        if (bestMix!.wc > 0)
                          Text(
                            "${bestMix!.c.name} ${(bestMix!.wc * 100).round()}%",
                            style: const TextStyle(color: Colors.white),
                          ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        "RGB: "
                        "${extractedColor.r * 255}, "
                        "${extractedColor.g * 255}, "
                        "${extractedColor.b * 255}",
                        style: TextStyle(
                          color: extractedColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//========== OpenCV 서비스 클래스 (로직 분리) ==========
// 이미지 크롭 및 대표색 추출을 OpenCV로 처리하는 서비스 클래스
// (실제 OpenCV 로직은 간단히 표현, 필요에 따라 세부 조정 가능)
// - cropROI: 화면 좌표 → 이미지 좌표 변환 후 크롭
// - simplifyByROI: 크롭된 이미지에서 대표색 추출

// class AdvancedRoiPicker extends StatefulWidget {
//   final Uint8List imageBytes;

//   const AdvancedRoiPicker({super.key, required this.imageBytes});

//   @override
//   State<AdvancedRoiPicker> createState() => _AdvancedRoiPickerState();
// }

// class _AdvancedRoiPickerState extends State<AdvancedRoiPicker> {
//   final TransformationController _controller = TransformationController();
//   late cv.Mat _srcMat;
//   bool _isMatReady = false;
//   bool _isMinimumCount = false;

//   final double _fixedRoiSize = 40;

//   Offset _roiPosition = const Offset(150, 250);

//   Uint8List? croppedPreview;
//   Color extractedColor = Colors.white;

//   late int imgW;
//   late int imgH;

//   double _drawW = 0;
//   double _drawH = 0;

//   double _imageOffsetX = 0;
//   double _imageOffsetY = 0;

//   List<PaintColorModel> paintDB = [];
//   List<PaintColorModel> recommendedPaints = [];
//   MixResultModel? bestMix;
//   List<Color> dominantColors = [];

//   @override
//   void initState() {
//     super.initState();

//     // final mat = cv.imdecode(widget.imageBytes, cv.IMREAD_UNCHANGED);

//     _srcMat = cv.imdecode(widget.imageBytes, cv.IMREAD_COLOR);

//     imgW = _srcMat.cols;
//     imgH = _srcMat.rows;

//     _isMatReady = true;

//     _initImage();
//     _loadPaintDB();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _updateRoiInfo();
//     });
//   }

//   Future<void> _initImage() async {
//     _srcMat = cv.imdecode(widget.imageBytes, cv.IMREAD_COLOR);

//     imgW = _srcMat.cols;
//     imgH = _srcMat.rows;

//     setState(() {});

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _updateRoiInfo();
//     });
//   }

//   Future<void> _loadPaintDB() async {
//     final jsonString = await rootBundle.loadString('assets/paint_db.json');

//     final List data = jsonDecode(jsonString);

//     paintDB = data.map((e) => PaintColorModel.fromJson(e)).toList();
//   }

//   double colorDistance(List<double> a, List<double> b) {
//     return math.sqrt(
//       math.pow(a[0] - b[0] * 0.8, 2) +
//           math.pow(a[1] - b[1], 2) +
//           math.pow(a[2] - b[2], 2),
//     );
//   }

//   // 성능 개선 버전
//   List<PaintColorModel> recommendPaints(List<double> targetLab) {
//     final top = paintDB
//       ..sort(
//         (a, b) => colorDistance(
//           a.lab,
//           targetLab,
//         ).compareTo(colorDistance(b.lab, targetLab)),
//       );

//     final candidates = top.take(5).toList();

//     if (_isMinimumCount) {
//       final mix2 = findBest2Mix(candidates, targetLab);
//       final mix3 = findBest3Mix(candidates, targetLab);
//       final best = mix2.distance < mix3.distance ? mix2 : mix3;
//       return best.paints;
//     }
//     return candidates;
//   }

//   // List<PaintColorModel> recommendPaints(List<double> targetLab) {
//   //   final sorted = [...paintDB];

//   //   sorted.sort((a, b) {
//   //     final da = colorDistance(targetLab, a.lab);

//   //     final db = colorDistance(targetLab, b.lab);

//   //     return da.compareTo(db);
//   //   });

//   //   return sorted.take(3).toList();
//   // }

//   Future<void> _updateRoiInfo() async {
//     if (_drawW == 0 || _drawH == 0) return;
//     try {
//       final matrix = _controller.value;

//       //----------------------------------
//       // ROI 중심점 (Stack 기준)
//       //----------------------------------
//       final roiCenter = Offset(
//         _roiPosition.dx + _fixedRoiSize / 2,
//         _roiPosition.dy + _fixedRoiSize / 2,
//       );

//       //----------------------------------
//       // 이미지 영역 기준 좌표
//       //----------------------------------
//       // final localPoint = Offset(
//       //   roiCenter.dx - _imageOffsetX,
//       //   roiCenter.dy - _imageOffsetY,
//       // );
//       final localPoint = roiCenter;

//       //----------------------------------
//       // 핵심: matrix inverse
//       //----------------------------------
//       final inverseMatrix = Matrix4.inverted(matrix);

//       // final transformed = MatrixUtils.transformPoint(inverseMatrix, localPoint);
//       final transformed = MatrixUtils.transformPoint(inverseMatrix, localPoint);

//       final imageX = (transformed.dx - _imageOffsetX).clamp(0.0, _drawW);

//       final imageY = (transformed.dy - _imageOffsetY).clamp(0.0, _drawH);

//       // final imageX = transformed.dx.clamp(0.0, _drawW);

//       // final imageY = transformed.dy.clamp(0.0, _drawH);

//       //----------------------------------
//       // 실제 원본 픽셀 변환
//       //----------------------------------
//       final px = (imageX / _drawW * imgW).toInt();

//       final py = (imageY / _drawH * imgH).toInt();

//       //----------------------------------
//       // ROI 실제 픽셀 크기
//       //----------------------------------
//       final scale = matrix.getMaxScaleOnAxis();

//       final roiPixelSize = (_fixedRoiSize / scale) * (imgW / _drawW);

//       final pw = roiPixelSize.toInt().clamp(1, imgW);

//       final ph = roiPixelSize.toInt().clamp(1, imgH);

//       final cutX = (px - pw ~/ 2).clamp(0, imgW - pw);

//       final cutY = (py - ph ~/ 2).clamp(0, imgH - ph);

//       //----------------------------------
//       // crop
//       //----------------------------------
//       final cropped = _srcMat.region(cv.Rect(cutX, cutY, pw, ph)).clone();

//       final (_, encoded) = cv.imencode(".jpg", cropped);

//       //----------------------------------
//       // RGB 평균
//       //----------------------------------
//       final rgbMean = cv.mean(cropped);

//       final rgbColor = Color.fromARGB(
//         255,
//         rgbMean.val[2].round(),
//         rgbMean.val[1].round(),
//         rgbMean.val[0].round(),
//       );

//       //----------------------------------
//       // LAB 평균
//       //----------------------------------
//       final labMat = cv.cvtColor(cropped, cv.COLOR_BGR2Lab);
//       final labMean = cv.mean(
//         labMat,
//       ); // LAB 평균값 계산 (L, A, B 순서로 val[0], val[1], val[2]에 저장)

//       // final targetLab = [labMean.val[0], labMean.val[1], labMean.val[2]];
//       final targetLab = [
//         labMean.val[0] * 100 / 255, // L 정규화
//         labMean.val[1] - 128, // a 정규화
//         labMean.val[2] - 128, // b 정규화
//       ];

//       final recommends = recommendPaints(targetLab);
//       final mixResult = findBestMix(targetLab, paintDB);

//       setState(() {
//         croppedPreview = encoded;

//         extractedColor = rgbColor;
//         recommendedPaints = recommends;
//         bestMix = mixResult;
//       });

//       cropped.dispose();
//       labMat.dispose();
//     } catch (e) {
//       debugPrint("ROI Error: $e");
//     }
//   }

//   MixResultModel findBestMix(
//     List<double> targetLab,
//     List<PaintColorModel> paints,
//   ) {
//     final candidates = recommendPaints(targetLab);

//     final a = candidates[0];
//     final b = candidates[1];
//     final c = candidates[2];

//     MixResultModel? best;

//     for (int i = 0; i <= 100; i += 5) {
//       for (int j = 0; j <= 100 - i; j += 5) {
//         int k = 100 - i - j;

//         final wa = i / 100;
//         final wb = j / 100;
//         final wc = k / 100;

//         final mixedLab = [
//           a.lab[0] * wa + b.lab[0] * wb + c.lab[0] * wc,

//           a.lab[1] * wa + b.lab[1] * wb + c.lab[1] * wc,

//           a.lab[2] * wa + b.lab[2] * wb + c.lab[2] * wc,
//         ];

//         final dist = colorDistance(targetLab, mixedLab);

//         if (best == null || dist < best.distance) {
//           best = MixResultModel(
//             a: a,
//             b: b,
//             c: c,
//             wa: wa,
//             wb: wb,
//             wc: wc,
//             distance: dist,
//           );
//         }
//       }
//     }

//     return best!;
//   }

//   List<Color> extractDominantColors(cv.Mat cropped) {
//     final rows = cropped.rows;
//     final cols = cropped.cols;

//     final samples = <List<double>>[];

//     for (int y = 0; y < rows; y += 2) {
//       for (int x = 0; x < cols; x += 2) {
//         final pixel = cropped.atVec(y, x); // BGR 순서로 반환 (예: [B, G, R])

//         // samples.add([
//         //   pixel[0].toDouble(), // B
//         //   pixel[1].toDouble(), // G
//         //   pixel[2].toDouble(), // R
//         // ]);
//         final b = pixel[0].toDouble();
//         final g = pixel[1].toDouble();
//         final r = pixel[2].toDouble();
//         samples.add([b, g, r]);
//       }
//     }

//     if (samples.isEmpty) return [];

//     final sampleMat = cv.Mat.fromList(
//       samples.length,
//       3,
//       // cv.MatType.CV_32F,
//       cv.MatType(cv.MatType.CV_32F),
//       samples.expand((e) => e).toList(),
//     );

//     final labels = cv.Mat.empty();
//     final centers = cv.Mat.empty();

//     cv.kmeans(
//       sampleMat,
//       3,
//       labels,
//       (cv.TERM_COUNT, 10, 1.0),
//       3,
//       cv.KMEANS_PP_CENTERS,
//       centers: centers,
//     );

//     List<Color> result = [];

//     for (int i = 0; i < centers.rows; i++) {
//       final b = centers.at<double>(i, 0).round();
//       final g = centers.at<double>(i, 1).round();
//       final r = centers.at<double>(i, 2).round();

//       result.add(Color.fromARGB(255, r, g, b));
//     }

//     sampleMat.dispose();
//     labels.dispose();
//     centers.dispose();

//     return result;
//   }

//   @override
//   void dispose() {
//     _controller.dispose();

//     if (_isMatReady) {
//       _srcMat.dispose();
//     }

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF111111),
//         foregroundColor: Colors.white,
//         title: const Text('색상 찾기', style: TextStyle(fontSize: 16)),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 final containerAspect =
//                     constraints.maxWidth / constraints.maxHeight;

//                 final imageAspect = imgW / imgH;

//                 if (containerAspect > imageAspect) {
//                   _drawH = constraints.maxHeight;
//                   _drawW = _drawH * imageAspect;
//                 } else {
//                   _drawW = constraints.maxWidth;
//                   _drawH = _drawW / imageAspect;
//                 }

//                 _imageOffsetX = (constraints.maxWidth - _drawW) / 2;

//                 _imageOffsetY = (constraints.maxHeight - _drawH) / 2;

//                 return Stack(
//                   children: [
//                     InteractiveViewer(
//                       transformationController: _controller,
//                       maxScale: 20,
//                       minScale: 1,
//                       clipBehavior: Clip.none,
//                       onInteractionUpdate: (_) {
//                         _updateRoiInfo();
//                       },
//                       child: Center(
//                         child: SizedBox(
//                           width: _drawW,
//                           height: _drawH,
//                           child: Image.memory(
//                             widget.imageBytes,
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),
//                     ),

//                     //--------------------------------
//                     // draggable ROI
//                     //--------------------------------
//                     Positioned(
//                       left: _roiPosition.dx,
//                       top: _roiPosition.dy,
//                       child: GestureDetector(
//                         onPanUpdate: (details) {
//                           setState(() {
//                             _roiPosition += details.delta;
//                           });

//                           _updateRoiInfo();
//                         },
//                         child: Container(
//                           width: _fixedRoiSize,
//                           height: _fixedRoiSize,
//                           decoration: BoxDecoration(
//                             border: Border.all(
//                               color: Colors.cyanAccent,
//                               width: 2,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     Positioned(
//                       bottom: 20,
//                       left: 0,
//                       right: 0,
//                       child: Text(
//                         "ROI를 이동하거나 이미지를 확대하세요",
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(color: Colors.white70),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),

//           //--------------------------------
//           // Bottom panel
//           //--------------------------------
//           Container(
//             height: 220,
//             color: const Color(0xFF111111),
//             padding: const EdgeInsets.all(20),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (croppedPreview != null)
//                   Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.white24),
//                     ),
//                     child: Image.memory(croppedPreview!, fit: BoxFit.fill),
//                   ),

//                 const SizedBox(width: 20),

//                 CircleAvatar(
//                   radius: 26,
//                   backgroundColor: Colors.grey.shade800,
//                   child: CircleAvatar(
//                     radius: 25,
//                     backgroundColor: extractedColor,
//                   ),
//                 ),

//                 const SizedBox(width: 15),

//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       // Text(
//                       //   "추천 유화 색상: ",
//                       //   style: const TextStyle(
//                       //     color: Colors.amber,
//                       //     fontSize: 18,
//                       //   ),
//                       // ),
//                       // ...recommendedPaints.map(
//                       //   (e) => Text(
//                       //     "${e.name} (${e.pigment})",
//                       //     style: const TextStyle(color: Colors.white),
//                       //   ),
//                       // ),
//                       if (bestMix != null) ...[
//                         const SizedBox(height: 20),

//                         const Text(
//                           "혼합 비율 추천",
//                           style: TextStyle(
//                             color: Colors.orange,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),

//                         const SizedBox(height: 10),
//                         if (bestMix!.wa > 0)
//                           Text(
//                             "${bestMix!.a.name} ${(bestMix!.wa * 100).round()}%",
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                         if (bestMix!.wb > 0)
//                           Text(
//                             "${bestMix!.b.name} ${(bestMix!.wb * 100).round()}%",
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                         if (bestMix!.wc > 0)
//                           Text(
//                             "${bestMix!.c.name} ${(bestMix!.wc * 100).round()}%",
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                       ],
//                       const SizedBox(height: 10),
//                       Text(
//                         "RGB: "
//                         "${extractedColor.r * 255}, "
//                         "${extractedColor.g * 255}, "
//                         "${extractedColor.b * 255}",
//                         style: TextStyle(
//                           color: extractedColor,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
