import 'package:flutter/material.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';
import 'package:image_editor/widgets/guide_grid.dart';

class UnifiedOverlay extends StatelessWidget {
  final ImageEditorState state;
  final int tabIndex;

  const UnifiedOverlay({
    super.key,
    required this.state,
    required this.tabIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: _buildCurrentLayer());
  }

  Widget _buildCurrentLayer() {
    switch (tabIndex) {
      case 0: // ROI — 박스만 표시, 분석 결과 없음
      case 2: // Paint — 박스 + 분석 결과 표시
        return RoiPaintOverlay(state: state, showAnalysis: tabIndex == 2);
      case 1: // Grid
        return GridOverlay(state: state);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── ROI 박스 + Paint 분석 결과 통합 오버레이 ──────────────────────────────
class RoiPaintOverlay extends StatelessWidget {
  final ImageEditorState state;
  final bool showAnalysis; // true: 색상 분석 결과 표시, false: 박스만

  const RoiPaintOverlay({
    super.key,
    required this.state,
    required this.showAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = state.controller.value;
    final double scale = matrix.row0.x;
    final double tx = matrix.row0.w;
    final double ty = matrix.row1.w;

    // InteractiveViewer(alignment:center)가 drawW×drawH 자식을 중앙에 배치
    // → 오버레이도 동일한 중앙 기준 좌표계 사용
    // → imageOffsetX/Y는 InteractiveViewer가 자동 처리하므로 더하지 않음
    final displayX = (state.roiPosition.dx * scale) + tx + state.imageOffsetX;
    final displayY = (state.roiPosition.dy * scale) + ty + state.imageOffsetY;

    return Stack(
      children: [
        Positioned(
          left: displayX,
          top: displayY,
          child: GestureDetector(
            onPanUpdate: (d) {
              state.updateRoi(state.roiPosition + (d.delta / scale));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── ROI 박스 ──────────────────────────────────
                Container(
                  width: state.roiSize,
                  height: state.roiSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    color: Colors.cyanAccent.withOpacity(0.08),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.open_with,
                      color: Colors.cyanAccent,
                      size: 14,
                    ),
                  ),
                ),

                // ── 분석 결과 말풍선 (Paint 탭일 때만) ──────────
                if (showAnalysis) ...[
                  const SizedBox(height: 6),
                  _AnalysisBubble(state: state),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 분석 결과 말풍선 ────────────────────────────────────────────────────────
class _AnalysisBubble extends StatelessWidget {
  final ImageEditorState state;
  const _AnalysisBubble({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 추출 색상
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: state.extractedColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '추출 색상',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),

          if (state.recommendedPaints.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '추천 유화 색',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 11),
            ),
            const SizedBox(height: 4),
            ...state.recommendedPaints
                .take(3)
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
          ],

          if (state.bestMix != null) ...[
            const SizedBox(height: 8),
            const Text(
              '혼합 비율',
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
            const SizedBox(height: 4),
            ...List.generate(state.bestMix!.paints.length, (i) {
              final w = state.bestMix!.weights[i];
              if (w <= 0) return const SizedBox.shrink();
              return Text(
                '${state.bestMix!.paints[i].name}  ${(w * 100).round()}%',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── 그리드 오버레이 ─────────────────────────────────────────────────────────
class GridOverlay extends StatelessWidget {
  final ImageEditorState state;

  const GridOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // InteractiveViewer가 drawW×drawH 자식을 중앙 배치하므로
    // 그리드도 동일하게 중앙에서 drawW×drawH 크기로 배치
    return Center(
      child: SizedBox(
        width: state.drawW,
        height: state.drawH,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: CenterBaseSquareGridPainter(
              divisions: state.gridDivisions,
              isWidthBase: state.gridWidthBase,
              lineColor: state.gridColor,
              strokeWidth: 1.0,
              showGrid: state.showGrid,
            ),
          ),
        ),
      ),
    );
  }
}
