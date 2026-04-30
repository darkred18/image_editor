import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dartcv4/dartcv.dart' as cv;

class PerspectiveCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const PerspectiveCropPage({super.key, required this.imageBytes});

  @override
  State<PerspectiveCropPage> createState() => _PerspectiveCropPageState();
}

class _PerspectiveCropPageState extends State<PerspectiveCropPage> {
  final List<Offset> points = [];
  int? draggingIndex;

  Size imageSize = Size.zero;
  final GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
  }

  Future<void> _decodeImageSize() async {
    final img = await decodeImageFromList(widget.imageBytes);
    setState(() {
      imageSize = Size(img.width.toDouble(), img.height.toDouble());
    });
  }

  // ---------------------------
  // 좌표 변환
  Offset toImageSpace(Offset p, Size widgetSize) {
    final scale = math.min(
      widgetSize.width / imageSize.width,
      widgetSize.height / imageSize.height,
    );

    final dx = (widgetSize.width - imageSize.width * scale) / 2;
    final dy = (widgetSize.height - imageSize.height * scale) / 2;

    final x = (p.dx - dx) / scale;
    final y = (p.dy - dy) / scale;

    return Offset(x, y);
  }

  // ---------------------------
  // 점 정렬 (좌상, 우상, 우하, 좌하)
  List<Offset> sortPoints(List<Offset> pts) {
    pts.sort((a, b) => a.dy.compareTo(b.dy));

    final top = pts.sublist(0, 2);
    final bottom = pts.sublist(2, 4);

    top.sort((a, b) => a.dx.compareTo(b.dx));
    bottom.sort((a, b) => a.dx.compareTo(b.dx));

    return [top[0], top[1], bottom[1], bottom[0]];
  }

  // ---------------------------
  // OpenCV 크롭
  Uint8List crop() {
    final box = imageKey.currentContext!.findRenderObject() as RenderBox;
    final widgetSize = box.size;

    final imagePoints = points.map((p) => toImageSpace(p, widgetSize)).toList();

    final sorted = sortPoints(imagePoints);

    final src = cv.imdecode(widget.imageBytes, cv.IMREAD_COLOR);

    final srcPts = sorted.map((e) => cv.Point2f(e.dx, e.dy)).toList();

    final width = 600.0;
    final height = 800.0;

    final dstPts = [
      cv.Point2f(0, 0),
      cv.Point2f(width, 0),
      cv.Point2f(width, height),
      cv.Point2f(0, height),
    ];
    final srcVec = cv.VecPoint2f.fromList(srcPts);
    final dstVec = cv.VecPoint2f.fromList(dstPts);

    // final M = cv.getPerspectiveTransform(srcVec, dstVec);

    // final dst = cv.Mat.empty();
    // cv.warpPerspective(src, dst, M, (width.toInt(), height.toInt()));

    // return cv.imencode(".jpg", dst);
    return Uint8List(0); // 임시 반환
  }

  // ---------------------------
  // 가장 가까운 점 찾기
  int? findNearbyPoint(Offset p) {
    for (int i = 0; i < points.length; i++) {
      if ((points[i] - p).distance < 20) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (imageSize == Size.zero) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perspective Crop"),
        actions: [
          IconButton(
            onPressed: points.length == 4
                ? () {
                    final result = crop();
                    // 결과 처리 (저장 / 화면 표시 등)
                  }
                : null,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (d) {
              if (points.length < 4) {
                setState(() => points.add(d.localPosition));
              }
            },
            onPanStart: (d) {
              draggingIndex = findNearbyPoint(d.localPosition);
            },
            onPanUpdate: (d) {
              if (draggingIndex != null) {
                setState(() {
                  points[draggingIndex!] = d.localPosition;
                });
              }
            },
            onPanEnd: (_) {
              draggingIndex = null;
            },
            child: Stack(
              children: [
                Center(
                  child: Image.memory(
                    widget.imageBytes,
                    key: imageKey,
                    fit: BoxFit.contain,
                  ),
                ),
                CustomPaint(
                  size: Size.infinite,
                  painter: _PointPainter(points),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------
// Painter
class _PointPainter extends CustomPainter {
  final List<Offset> points;

  _PointPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()..color = Colors.red;
    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 6, pointPaint);
    }

    if (points.length == 4) {
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
