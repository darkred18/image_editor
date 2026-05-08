import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_editor/models/painting_data_model.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';

class PaintAnalysisPainter extends CustomPainter {
  final ImageEditorState state;

  PaintAnalysisPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    //--------------------------------
    // ROI 박스
    //--------------------------------
    final roiPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(
      state.roiPosition.dx,
      state.roiPosition.dy,
      state.roiSize,
      state.roiSize,
    );

    canvas.drawRect(rect, roiPaint);

    //--------------------------------
    // 중심점
    //--------------------------------
    final centerPaint = Paint()
      ..color = const Color(0xFFFF4081)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(rect.center, 3, centerPaint);

    //--------------------------------
    // dominant colors (우측 상단)
    //--------------------------------
    double x = size.width - 30;
    double y = 10;

    for (final c in state.dominantColors) {
      final p = Paint()..color = c;

      canvas.drawCircle(Offset(x, y), 8, p);

      y += 20;
    }

    //--------------------------------
    // 혼합 결과 색 표시 (좌측 상단)
    //--------------------------------
    if (state.bestMix != null) {
      final mixedColor = _mixToColor(state.bestMix!);

      final p = Paint()..color = mixedColor;

      canvas.drawCircle(const Offset(20, 20), 12, p);
    }
  }

  //--------------------------------
  // LAB → RGB 간단 변환
  //--------------------------------
  Color _mixToColor(MixResultModel2 mix) {
    double L = 0, A = 0, B = 0;

    for (int i = 0; i < mix.paints.length; i++) {
      L += mix.paints[i].lab[0] * mix.weights[i];
      A += mix.paints[i].lab[1] * mix.weights[i];
      B += mix.paints[i].lab[2] * mix.weights[i];
    }

    return _labToColor(L, A, B);
  }

  //--------------------------------
  // LAB → RGB
  //--------------------------------
  Color _labToColor(double l, double a, double b) {
    // LAB → XYZ
    double y = (l + 16) / 116;
    double x = a / 500 + y;
    double z = y - b / 200;

    x = _pivotXYZ(x) * 95.047;
    y = _pivotXYZ(y) * 100.0;
    z = _pivotXYZ(z) * 108.883;

    // XYZ → RGB
    x /= 100;
    y /= 100;
    z /= 100;

    double r = x * 3.2406 + y * -1.5372 + z * -0.4986;
    double g = x * -0.9689 + y * 1.8758 + z * 0.0415;
    double b2 = x * 0.0557 + y * -0.2040 + z * 1.0570;

    r = _pivotRGB(r);
    g = _pivotRGB(g);
    b2 = _pivotRGB(b2);

    return Color.fromARGB(
      255,
      (r * 255).clamp(0, 255).toInt(),
      (g * 255).clamp(0, 255).toInt(),
      (b2 * 255).clamp(0, 255).toInt(),
    );
  }

  double _pivotXYZ(double n) {
    return n > 0.206893034 ? n * n * n : (n - 16 / 116) / 7.787;
  }

  double _pivotRGB(double n) {
    return n > 0.0031308 ? 1.055 * pow(n, 1 / 2.4) - 0.055 : 12.92 * n;
  }

  @override
  bool shouldRepaint(covariant PaintAnalysisPainter oldDelegate) {
    return true;
  }
}
