import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'image_simplification_service.dart';

class ImageSimplificationScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageSimplificationScreen({super.key, required this.imageBytes});

  @override
  State<ImageSimplificationScreen> createState() =>
      _ImageSimplificationScreenState();
}

class _ImageSimplificationScreenState extends State<ImageSimplificationScreen> {
  // 파라미터
  int _colorCount = 8;
  double _sigmaColor = 75;
  double _sigmaSpace = 75;

  // 결과
  SimplificationResult? _result;
  bool _isProcessing = false;
  bool _showOriginal = false; // 원본/결과 토글

  @override
  void initState() {
    super.initState();
    _process(); // 진입 시 기본값으로 바로 처리
  }

  Future<void> _process() async {
    setState(() => _isProcessing = true);
    try {
      // final result = await ImageSimplificationService.simplify(
      //   imageBytes: widget.imageBytes,
      //   colorCount: _colorCount,
      //   sigmaColor: _sigmaColor,
      //   sigmaSpace: _sigmaSpace,
      // );
      // UI에서 선택된 단계 (예: 슬라이더나 버튼으로 관리되는 변수)
      int currentStep = 1; // 1: 초벌, 2: 중간, 3: 세부

      // 서비스 호출 부분 수정
      // final result = await ImageSimplificationService.simplify(
      //   imageBytes: widget.imageBytes,
      //   step: currentStep, // 파라미터를 step 하나로 통일
      // );

      final Uint8List bytes = widget.imageBytes; // 순수 데이터만 복사

      // 3. 실행
      final result = await compute(ImageSimplificationService.runSimplify, {
        'imageBytes': bytes,
        'colorCount': _colorCount,
        'sigmaColor': _sigmaColor,
        'sigmaSpace': _sigmaSpace,
        'lowThreshold': _sigmaColor, // Canny low threshold
        'highThreshold': _sigmaSpace, // Canny high threshold
      });

      if (mounted) setState(() => _result = result);
    } catch (e) {
      print(e);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("에러 발생"),
            content: SingleChildScrollView(
              child: Text(e.toString()),
            ), // 에러 내용 고정
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("확인"),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        title: const Text('이미지 단순화', style: TextStyle(fontSize: 16)),
        actions: [
          // 원본/결과 토글
          GestureDetector(
            onTapDown: (_) => setState(() => _showOriginal = true),
            onTapUp: (_) => setState(() => _showOriginal = false),
            onTapCancel: () => setState(() => _showOriginal = false),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(
                '원본 비교',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 이미지 미리보기 ──
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 결과 or 원본 표시
                if (_result != null && !_showOriginal)
                  InteractiveViewer(
                    child: Image.memory(
                      _result!.imageBytes,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  InteractiveViewer(
                    child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                  ),

                // 처리 중 오버레이
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF00E5FF)),
                          SizedBox(height: 12),
                          Text(
                            '분석 중…',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 원본 비교 레이블
                if (_showOriginal)
                  const Positioned(top: 12, child: _Badge(label: '원본')),
              ],
            ),
          ),

          // ── 색상 팔레트 ──
          if (_result != null) _PaletteRow(colors: _result!.palette),

          // ── 파라미터 슬라이더 패널 ──
          _ControlPanel(
            colorCount: _colorCount,
            sigmaColor: _sigmaColor,
            sigmaSpace: _sigmaSpace,
            isProcessing: _isProcessing,
            onColorCountChanged: (v) => setState(() => _colorCount = v),
            onSigmaColorChanged: (v) => setState(() => _sigmaColor = v),
            onSigmaSpaceChanged: (v) => setState(() => _sigmaSpace = v),
            onApply: _process,
          ),
        ],
      ),
    );
  }
}

// ── 팔레트 행 ──────────────────────────────────────────────────────────────
class _PaletteRow extends StatelessWidget {
  final List<Color> colors;
  const _PaletteRow({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text(
            '팔레트',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => Tooltip(
                message:
                    '#${colors[i].value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 컨트롤 패널 ────────────────────────────────────────────────────────────
class _ControlPanel extends StatelessWidget {
  final int colorCount;
  final double sigmaColor;
  final double sigmaSpace;
  final bool isProcessing;
  final ValueChanged<int> onColorCountChanged;
  final ValueChanged<double> onSigmaColorChanged;
  final ValueChanged<double> onSigmaSpaceChanged;
  final VoidCallback onApply;

  const _ControlPanel({
    required this.colorCount,
    required this.sigmaColor,
    required this.sigmaSpace,
    required this.isProcessing,
    required this.onColorCountChanged,
    required this.onSigmaColorChanged,
    required this.onSigmaSpaceChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1C),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          _SliderRow(
            label: '색상 수',
            value: colorCount.toDouble(),
            min: 2,
            max: 24,
            divisions: 22,
            valueLabel: '$colorCount색',
            onChanged: (v) => onColorCountChanged(v.round()),
          ),
          _SliderRow(
            label: '색 혼합',
            value: sigmaColor,
            min: 10,
            max: 150,
            valueLabel: sigmaColor.round().toString(),
            onChanged: onSigmaColorChanged,
          ),
          _SliderRow(
            label: '블러 범위',
            value: sigmaSpace,
            min: 10,
            max: 150,
            valueLabel: sigmaSpace.round().toString(),
            onChanged: onSigmaSpaceChanged,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isProcessing ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black54,
                      ),
                    )
                  : const Text(
                      '적용',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00E5FF),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: const Color(0x2200E5FF),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
