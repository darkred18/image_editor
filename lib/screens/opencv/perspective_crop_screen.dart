import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'crop_overlay_painter.dart';
import 'perspective_transform_service.dart';

/// 이미지 위에 4-코너 드래그 크롭 + Perspective Transform 화면
///
/// 사용 예:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => PerspectiveCropScreen(imageBytes: yourUint8List),
/// ));
/// ```
class PerspectiveCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const PerspectiveCropScreen({super.key, required this.imageBytes});

  @override
  State<PerspectiveCropScreen> createState() => _PerspectiveCropScreenState();
}

class _PerspectiveCropScreenState extends State<PerspectiveCropScreen> {
  List<CropPoint> _points = [];
  int? _draggingIndex;
  bool _isProcessing = false;

  // BoxFit.contain 후 이미지가 실제로 그려지는 Rect (레터박스 제외)
  Rect _imageRect = Rect.zero;

  // 원본 이미지 크기 (디코딩 후 확정)
  Size _imageSize = Size.zero;

  static const double _hitRadius = 32.0;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  /// 이미지 바이트에서 실제 픽셀 크기를 비동기로 읽어옴
  Future<void> _resolveImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    if (!mounted) return;
    setState(() {
      _imageSize = Size(img.width.toDouble(), img.height.toDouble());
    });
  }

  /// 컨테이너 크기 + 이미지 비율로 BoxFit.contain Rect 계산
  Rect _calcImageRect(Size containerSize) {
    if (_imageSize == Size.zero) return Rect.zero;

    final imageAspect = _imageSize.width / _imageSize.height;
    final containerAspect = containerSize.width / containerSize.height;

    double w, h;
    if (imageAspect > containerAspect) {
      // 가로에 맞춤 → 위아래 레터박스
      w = containerSize.width;
      h = containerSize.width / imageAspect;
    } else {
      // 세로에 맞춤 → 좌우 레터박스
      h = containerSize.height;
      w = containerSize.height * imageAspect;
    }

    final left = (containerSize.width - w) / 2;
    final top = (containerSize.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  /// imageRect 확정 후 초기 4-코너 배치 (이미지 안쪽 10% 여백)
  void _initPoints(Rect rect) {
    if (rect == _imageRect || rect == Rect.zero) return;
    _imageRect = rect;
    final pad = rect.shortestSide * 0.10;
    setState(() {
      _points = [
        CropPoint(
          position: Offset(rect.left + pad, rect.top + pad),
          label: 'TL',
        ),
        CropPoint(
          position: Offset(rect.right - pad, rect.top + pad),
          label: 'TR',
        ),
        CropPoint(
          position: Offset(rect.right - pad, rect.bottom - pad),
          label: 'BR',
        ),
        CropPoint(
          position: Offset(rect.left + pad, rect.bottom - pad),
          label: 'BL',
        ),
      ];
    });
  }

  int? _hitTest(Offset local) {
    for (int i = 0; i < _points.length; i++) {
      if ((_points[i].position - local).distance < _hitRadius) return i;
    }
    return null;
  }

  Future<void> _applyCrop() async {
    if (_imageRect == Rect.zero) return;
    setState(() => _isProcessing = true);

    try {
      final result = await PerspectiveTransformService.transform(
        imageBytes: widget.imageBytes,
        points: _points, // 화면 원본 좌표 그대로 전달
        imageRect: _imageRect, // offset + 크기를 service에서 한 번에 처리
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _CropResultScreen(resultBytes: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변환 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('영역 선택', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _applyCrop,
            child: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00E5FF),
                    ),
                  )
                : const Text(
                    '변환',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 16),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final containerSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                // 이미지 크기가 확정된 후에만 Rect 계산 + 포인트 초기화
                if (_imageSize != Size.zero) {
                  final rect = _calcImageRect(containerSize);
                  // build 중 setState 금지 → postFrameCallback
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initPoints(rect);
                  });
                }

                return Listener(
                  // PointerEvent 레벨에서 직접 처리 → PageView 경쟁 우선
                  onPointerDown: (e) {
                    final hit = _hitTest(e.localPosition);
                    if (hit != null) {
                      setState(() => _draggingIndex = hit);
                    }
                  },
                  onPointerMove: (e) {
                    if (_draggingIndex == null) return;
                    setState(() {
                      final raw = _points[_draggingIndex!].position + e.delta;
                      final clamped = Offset(
                        raw.dx.clamp(_imageRect.left, _imageRect.right),
                        raw.dy.clamp(_imageRect.top, _imageRect.bottom),
                      );
                      _points[_draggingIndex!] = _points[_draggingIndex!]
                          .copyWith(position: clamped);
                    });
                  },
                  onPointerUp: (_) => setState(() => _draggingIndex = null),
                  onPointerCancel: (_) => setState(() => _draggingIndex = null),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 원본 이미지
                      Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                      // 크롭 오버레이
                      if (_points.length == 4)
                        CustomPaint(
                          painter: CropOverlayPainter(
                            points: _points,
                            draggingIndex: _draggingIndex,
                          ),
                        ),
                      // 로딩
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF111111),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Text(
              '코너 점을 드래그해 영역을 맞추세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 결과 미리보기 화면 ──────────────────────────────────────────────────────
class _CropResultScreen extends StatelessWidget {
  final Uint8List resultBytes;
  const _CropResultScreen({required this.resultBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('결과', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF00E5FF)),
            onPressed: () {
              // 결과 바이트를 상위로 전달하거나 저장 처리
              Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        ],
      ),
      body: Center(child: InteractiveViewer(child: Image.memory(resultBytes))),
    );
  }
}
