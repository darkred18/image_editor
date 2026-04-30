import 'dart:typed_data';
import 'dart:ui';
import 'package:dartcv4/dartcv.dart' as cv;

class PerspectiveTransformService {
  /// [imageBytes]    : 원본 이미지 바이트 (jpg/png)
  /// [points]        : 화면 전체 좌표계의 4개 코너 (TL, TR, BR, BL 순서)
  /// [imageRect]     : BoxFit.contain 후 이미지가 실제로 렌더링된 Rect
  ///                   (레터박스 offset + 렌더링 크기를 모두 포함)
  /// [outputWidth] / [outputHeight] : 결과 크기 (미지정 시 자동 계산)
  static Future<Uint8List> transform({
    required Uint8List imageBytes,
    required List<CropPoint> points,
    required Rect imageRect, // ← displaySize 대신 Rect 전체를 받음
    int? outputWidth,
    int? outputHeight,
  }) async {
    // 1. 바이트 → cv::Mat 디코딩
    final src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
    if (src.isEmpty) throw Exception('이미지 디코딩 실패');

    final imgSize = Size(src.cols.toDouble(), src.rows.toDouble());

    // 2. 화면 좌표 → 실제 이미지 픽셀 좌표 변환
    //    - imageRect.left/top : 레터박스 offset 제거
    //    - imageRect.size     : 렌더링 크기 기준 스케일 적용
    final scaleX = imgSize.width / imageRect.width;
    final scaleY = imgSize.height / imageRect.height;

    Offset toPixel(Offset screen) => Offset(
      (screen.dx - imageRect.left) * scaleX,
      (screen.dy - imageRect.top) * scaleY,
    );

    final tl = toPixel(points[0].position);
    final tr = toPixel(points[1].position);
    final br = toPixel(points[2].position);
    final bl = toPixel(points[3].position);

    // 3. 출력 크기 자동 계산
    final dstW =
        outputWidth?.toDouble() ?? _maxOf(_dist(tl, tr), _dist(bl, br));
    final dstH =
        outputHeight?.toDouble() ?? _maxOf(_dist(tl, bl), _dist(tr, br));

    // 4. 소스 4점 → VecPoint
    final srcVec = cv.VecPoint.fromList([
      cv.Point(tl.dx.round(), tl.dy.round()),
      cv.Point(tr.dx.round(), tr.dy.round()),
      cv.Point(br.dx.round(), br.dy.round()),
      cv.Point(bl.dx.round(), bl.dy.round()),
    ]);

    // 5. 목적지 4점 → VecPoint (직사각형)
    final dstVec = cv.VecPoint.fromList([
      cv.Point(0, 0),
      cv.Point(dstW.round(), 0),
      cv.Point(dstW.round(), dstH.round()),
      cv.Point(0, dstH.round()),
    ]);

    // 6. 변환 행렬 계산
    final M = cv.getPerspectiveTransform(srcVec, dstVec);

    // 7. Perspective Warp 적용
    final dst = cv.warpPerspective(src, M, (dstW.toInt(), dstH.toInt()));

    // 8. 결과 인코딩
    final (_, encoded) = cv.imencode(
      '.jpg',
      dst,
      params: cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, 95]),
    );

    src.dispose();
    dst.dispose();
    M.dispose();

    return encoded;
  }

  static double _dist(Offset a, Offset b) => (a - b).distance;
  static double _maxOf(double a, double b) => a > b ? a : b;
}

/// 이미지 위에서 사용자가 지정하는 4개의 코너 포인트
class CropPoint {
  Offset position;
  final String label; // TL, TR, BR, BL

  CropPoint({required this.position, required this.label});

  CropPoint copyWith({Offset? position}) =>
      CropPoint(position: position ?? this.position, label: label);
}

/// 디스플레이 좌표 → 이미지 실제 픽셀 좌표 변환
Offset toImageCoord(
  Offset displayPoint, {
  required Size displaySize,
  required Size imageSize,
}) {
  final scaleX = imageSize.width / displaySize.width;
  final scaleY = imageSize.height / displaySize.height;
  return Offset(displayPoint.dx * scaleX, displayPoint.dy * scaleY);
}
