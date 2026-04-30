import 'package:flutter/material.dart';

import 'perspective_transform_service.dart';

class CropOverlayPainter extends CustomPainter {
  final List<CropPoint> points;
  final int? draggingIndex;

  CropOverlayPainter({required this.points, this.draggingIndex});

  static const Color _lineColor = Color(0xFF00E5FF);
  static const Color _pointColor = Color(0xFFFFFFFF);
  static const Color _activeColor = Color(0xFFFFD600);
  static const Color _shadowColor = Color(0x88000000);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 4) return;

    // ── 사각형 반투명 오버레이 (바깥 영역 어둡게) ──
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..moveTo(points[0].position.dx, points[0].position.dy)
      ..lineTo(points[1].position.dx, points[1].position.dy)
      ..lineTo(points[2].position.dx, points[2].position.dy)
      ..lineTo(points[3].position.dx, points[3].position.dy)
      ..close();
    final overlay = Path.combine(PathOperation.difference, path, innerPath);
    canvas.drawPath(overlay, Paint()..color = _shadowColor);

    // ── 테두리 선 (4점 연결) ──
    final linePaint = Paint()
      ..color = _lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final borderPath = Path()
      ..moveTo(points[0].position.dx, points[0].position.dy)
      ..lineTo(points[1].position.dx, points[1].position.dy)
      ..lineTo(points[2].position.dx, points[2].position.dy)
      ..lineTo(points[3].position.dx, points[3].position.dy)
      ..close();
    canvas.drawPath(borderPath, linePaint);

    // ── 대각선 (보조 가이드) ──
    final diagPaint = Paint()
      ..color = _lineColor.withOpacity(0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(points[0].position, points[2].position, diagPaint);
    canvas.drawLine(points[1].position, points[3].position, diagPaint);

    // ── 코너 핸들 포인트 ──
    for (int i = 0; i < points.length; i++) {
      final isActive = i == draggingIndex;
      final p = points[i].position;

      // 그림자
      canvas.drawCircle(
        p.translate(1.5, 1.5),
        isActive ? 14 : 10,
        Paint()..color = Colors.black38,
      );

      // 외곽 링
      canvas.drawCircle(
        p,
        isActive ? 14 : 10,
        Paint()
          ..color = isActive ? _activeColor : _lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 내부 채우기
      canvas.drawCircle(
        p,
        isActive ? 8 : 5,
        Paint()..color = isActive ? _activeColor : _pointColor,
      );

      // ── L자 모서리 마커 (각 코너에) ──
      _drawCornerMarker(canvas, p, i, isActive);
    }
  }

  /// 각 코너에 L자형 마커를 그려 방향감 부여
  void _drawCornerMarker(Canvas canvas, Offset p, int index, bool isActive) {
    const len = 16.0;
    const th = 2.5;
    final color = isActive ? _activeColor : _lineColor;
    final paint = Paint()
      ..color = color
      ..strokeWidth = th
      ..strokeCap = StrokeCap.round;

    switch (index) {
      case 0: // TL
        canvas.drawLine(p, p.translate(len, 0), paint);
        canvas.drawLine(p, p.translate(0, len), paint);
        break;
      case 1: // TR
        canvas.drawLine(p, p.translate(-len, 0), paint);
        canvas.drawLine(p, p.translate(0, len), paint);
        break;
      case 2: // BR
        canvas.drawLine(p, p.translate(-len, 0), paint);
        canvas.drawLine(p, p.translate(0, -len), paint);
        break;
      case 3: // BL
        canvas.drawLine(p, p.translate(len, 0), paint);
        canvas.drawLine(p, p.translate(0, -len), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(CropOverlayPainter old) =>
      old.points != points || old.draggingIndex != draggingIndex;
}
