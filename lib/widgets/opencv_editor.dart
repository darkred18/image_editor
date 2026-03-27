import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dartcv4/dartcv.dart' as cv;

class OpenCVEditorPage extends StatefulWidget {
  const OpenCVEditorPage({super.key, required this.imagePath});
  final String imagePath;

  @override
  State<OpenCVEditorPage> createState() => _OpenCVEditorPageState();
}

class _OpenCVEditorPageState extends State<OpenCVEditorPage> {
  late Uint8List imageBytes; // 가공된 이미지 데이터 저장
  Uint8List? _processedImageBytes; // 가공된 이미지 데이터 저장
  bool _isLoading = false; // 로딩 상태

  // 4개의 꼭짓점 위치 (좌상, 우상, 좌하, 우하 순서 권장)
  // 1. 점들의 위치를 저장할 리스트 (화면 좌표계)
  final List<Offset> _points = [
    Offset(50, 50), // 좌상
    Offset(200, 50), // 우상
    Offset(200, 200), // 우하
    Offset(50, 200), // 좌하
  ];
  bool _isInitialized = true;
  // 마커 스타일 정의
  final double _markerSize = 24.0;
  final Color _markerColor = Colors.blueAccent;

  // // 1. 갤러리에서 이미지 불러오기 및 처리 시작
  // Future<void> _pickAndProcessImage() async {
  //   final XFile? pickedFile = await _picker.pickImage(
  //     source: ImageSource.gallery,
  //   );

  //   if (pickedFile == null) return; // 선택 안 함

  //   setState(() {
  //     _isLoading = true;
  //     _processedImageBytes = null; // 이전 이미지 초기화
  //   });

  //   // 메인 스레드 차단을 막기 위해 처리 로직을 비동기로 실행
  //   await _processImageWithOpenCV(pickedFile.path);
  // }

  // 2. OpenCV 이미지 처리 로직 (핵심)
  Future<void> _processImageWithOpenCV() async {
    try {
      // (A) 파일 경로에서 Mat 객체 생성
      final mat = cv.imread(widget.imagePath);

      if (mat.isEmpty) {
        throw Exception("이미지를 읽을 수 없습니다.");
      }

      // (B) [유화 앱 예시] 이미지 가공: 흑백 변환 후 윤곽선 추출
      // 원본은BGR이므로 GRAY로 변환
      final grayMat = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);

      // 캐니 엣지 검출 (윤곽선 강조)
      // final edgesMat = cv.Canny(grayMat, 50, 150);

      // (C) 가공된 Mat을 Flutter용 Uint8List로 변환
      // .jpg 포맷으로 인코딩
      final (success, bytes) = cv.imencode(".jpg", grayMat);

      if (success) {
        setState(() {
          _processedImageBytes = Uint8List.fromList(bytes);
        });
      }

      // (D) 사용한 Mat 객체들 메모리 해제 (매우 중요)
      mat.dispose();
      grayMat.dispose();
    } catch (e) {
      debugPrint("OpenCV 처리 중 에러 발생: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("이미지 처리 중 오류가 발생했습니다.")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final mat = cv.imread(widget.imagePath);
    final (success, bytes) = cv.imencode(".jpg", mat);

    _processedImageBytes = bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // 다크 모드 배경
      appBar: AppBar(
        title: const Text("유화 구도 분석 (OpenCV)", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          // LayoutBuilder를 사용하여 이미지가 그려질 실제 크기를 파악
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 최초 1회만 마커 위치 초기화 (이미지 영역 중앙 근처에 사각형으로)
              if (!_isInitialized) {
                _initializePoints(constraints.maxWidth, constraints.maxHeight);
                _isInitialized = true;
              }

              return Stack(
                clipBehavior: Clip.none, // 마커가 이미지 경계에 걸쳐도 보이게
                children: [
                  // 1. 원본 이미지 레이어
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _processedImageBytes != null
                        ? Image.memory(
                            _processedImageBytes!,
                            fit: BoxFit.contain,
                            // 이미지가 교체될 때 깜빡임을 방지하려면 true로 설정
                            gaplessPlayback: true,
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),

                  // 2. 가이드 라인 레이어 (4개의 점을 잇는 선)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GuidelinePainter(
                        points: _points,
                        color: _markerColor.withOpacity(0.5),
                      ),
                    ),
                  ),

                  // 3. 드래그 가능한 마커 레이어 (4개)
                  ...List.generate(
                    4,
                    (index) => _buildDraggableMarker(index, constraints),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.photo_library),
                label: const Text(" open cv 변환"),
                onPressed: applyPerspectiveTransform,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(int index) {
    return Positioned(
      left: _points[index].dx - 15, // 마커 중심 맞추기
      top: _points[index].dy - 15,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // 현재 마커의 위치를 드래그한 만큼 업데이트
            _points[index] += details.delta;
          });
        },
        child: CircleAvatar(
          radius: 15,
          backgroundColor: Colors.red.withOpacity(0.8),
          child: Text(
            "${index + 1}",
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // 마커 초기 위치 설정 (화면 크기에 비례하여 중앙 사각형)
  void _initializePoints(double width, double height) {
    // 현재 프레임 그리기가 끝난 후 실행되도록 예약
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        setState(() {
          _points.addAll([
            Offset(width * 0.2, height * 0.2), // 좌상
            Offset(width * 0.8, height * 0.2), // 우상
            Offset(width * 0.2, height * 0.8), // 좌하
            Offset(width * 0.8, height * 0.8), // 우하
          ]);
          _isInitialized = true;
        });
      }
    });
  }

  Rect getBoundingBox(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;

    // 모든 x값 중 최소/최대, 모든 y값 중 최소/최대를 찾음
    double minX = points.map((p) => p.dx).reduce(min);
    double maxX = points.map((p) => p.dx).reduce(max);
    double minY = points.map((p) => p.dy).reduce(min);
    double maxY = points.map((p) => p.dy).reduce(max);

    // Rect 객체로 반환
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Rect calculateBounds(Offset p1, Offset p2, Offset p3, Offset p4) {
    final left = min(min(p1.dx, p2.dx), min(p3.dx, p4.dx));
    final top = min(min(p1.dy, p2.dy), min(p3.dy, p4.dy));
    final right = max(max(p1.dx, p2.dx), max(p3.dx, p4.dx));
    final bottom = max(max(p1.dy, p2.dy), max(p3.dy, p4.dy));

    return Rect.fromLTRB(left, top, right, bottom);
  }

  // 개별 드래그 마커 위젯 빌드
  Widget _buildDraggableMarker(int index, BoxConstraints constraints) {
    return Positioned(
      left: _points[index].dx - (_markerSize / 2),
      top: _points[index].dy - (_markerSize / 2),
      child: GestureDetector(
        // 드래그 업데이트 이벤트 처리
        onPanUpdate: (details) {
          setState(() {
            // 터치 이동량(delta)만큼 마커 위치 이동
            double newX = _points[index].dx + details.delta.dx;
            double newY = _points[index].dy + details.delta.dy;

            // 마커가 이미지 영역(constraints) 밖으로 나가지 않도록 제한
            newX = newX.clamp(0.0, constraints.maxWidth);
            newY = newY.clamp(0.0, constraints.maxHeight);

            _points[index] = Offset(newX, newY);
          });
        },
        child: Container(
          width: _markerSize,
          height: _markerSize,
          decoration: BoxDecoration(
            color: _markerColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "${index + 1}", // 점 순서 표시 (개발자/사용자 확인용)
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 완료 버튼 누를 때 호출 (좌표 추출 및 다음 단계로 전달)
  void _getFinalPoints() {
    // 여기서 얻은 _points 리스트를 dartcv4의 VecPoint2f로 변환하여 사용하면 됩니다.
    debugPrint("선택된 좌표 (Flutter Offset):");
    for (int i = 0; i < _points.length; i++) {
      debugPrint(
        "점 $i: (${_points[i].dx.toStringAsFixed(1)}, ${_points[i].dy.toStringAsFixed(1)})",
      );
    }

    // 예시: 다음 화면으로 좌표 전달하면서 이동
    // Navigator.push(context, MaterialPageRoute(builder: (context) => OpenCVWarpPage(points: _points)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("좌표가 선택되었습니다. OpenCV 처리를 시작합니다.")),
    );
  }

  List<double> _getActualPixels(
    Size displaySize,
    int actualWidth,
    int actualHeight,
  ) {
    List<double> actualPoints = [];
    for (var point in _points) {
      // (화면 좌표 / 현재 화면 이미지 크기) * 실제 이미지 해상도
      double px = (point.dx / displaySize.width) * actualWidth;
      double py = (point.dy / displaySize.height) * actualHeight;
      actualPoints.addAll([px, py]);
    }
    return actualPoints;
  }

  cv.VecPoint _getConvertPoints(List<Offset> points) {
    // 1. Offset 리스트를 [x1, y1, x2, y2...] 형태의 double 리스트로 변환
    final rawPoints = points.expand((p) => [p.dx, p.dy]).toList();

    // 2. Mat 생성 (4행 1열, 2채널 float 타입)
    final srcPointsMat = cv.Mat.fromList(4, 1, cv.MatType.CV_32FC2, rawPoints);

    // 3. 해결하신 방식대로 VecPoint로 변환
    final src = cv.VecPoint.fromMat(srcPointsMat);

    return src;
  }

  void applyPerspectiveTransform() {
    // 1. 원본 이미지 읽기
    // final img = cv.imread(widget.imagePath);
    final img = cv.imdecode(_processedImageBytes!, cv.COLOR_BGR2RGB);
    if (img.isEmpty) return;

    // // 2. 원본에서 왜곡된 4지점 (좌상, 우상, 좌하, 우하)
    // // 포인트는 반드시 Point2f(float32) 형태의 Mat이어야 합니다.
    // final srcPoints = cv.Mat.fromList(4, 1, cv.MatType.CV_32FC2, [
    //   152.0, 180.0, // 첫 번째 점 (x, y)
    //   860.0, 210.0, // 두 번째 점
    //   100.0, 950.0, // 세 번째 점
    //   920.0, 910.0, // 네 번째 점
    // ]);

    // // 3. 변환 후의 4지점 (결과물에서의 좌표 - 500x500 직사각형)
    // final dstPoints = cv.Mat.fromList(4, 1, cv.MatType.CV_32FC2, [
    //   0.0,
    //   0.0,
    //   500.0,
    //   0.0,
    //   0.0,
    //   500.0,
    //   500.0,
    //   500.0,
    // ]);
    final bb = getBoundingBox(_points);
    final bbPoints = [bb.topLeft, bb.topRight, bb.bottomRight, bb.bottomLeft];

    final src = _getConvertPoints(_points);
    final dst = _getConvertPoints(bbPoints);
    // 4. 변환 행렬(M) 계산
    final M = cv.getPerspectiveTransform(src, dst);

    // 5. 원근 변환 적용 (결과 사이즈는 500x500)
    final correctedImg = cv.warpPerspective(img, M, (500, 500));

    // 6. 결과 확인 및 저장/표시 (예: jpg 인코딩)
    final (success, bytes) = cv.imencode(".jpg", correctedImg);
    if (success) {
      // 이 bytes(Uint8List)를 Image.memory()로 화면에 뿌려주면 됩니다.
      setState(() {
        _processedImageBytes = bytes;
      });
    }
    // 7. 메모리 해제 (dartcv4는 수동 해제가 성능상 유리합니다)
    img.dispose();
    // srcPoints.dispose();
    // dstPoints.dispose();
    M.dispose();
    correctedImg.dispose();
  }
}

// 4개의 점을 잇는 사각형 가이드라인 페인터
class GuidelinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  GuidelinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 4) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 점들을 잇는 경로 생성 (순서 중요: 좌상 -> 우상 -> 우하 -> 좌하 -> 닫기)
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy) // 좌상
      ..lineTo(points[1].dx, points[1].dy) // 우상
      ..lineTo(points[3].dx, points[3].dy) // 우하 (순서 바꿈 주의: 대각선 안 생기게)
      ..lineTo(points[2].dx, points[2].dy) // 좌하
      ..close(); // 다시 좌상으로 연결

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GuidelinePainter oldDelegate) => true;
}
