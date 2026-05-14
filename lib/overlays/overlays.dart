import 'package:flutter/material.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';
import 'package:image_editor/screens/edit_screen.dart';
import 'package:image_editor/widgets/guide_grid.dart';

class UnifiedOverlay extends StatelessWidget {
  final ImageEditorState state;
  final EditorTab tabIndex;

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
    switch (state.tabIndex) {
      case EditorTab.crop:
      case EditorTab.colorAnalysis:
        return RoiPaintOverlay(state: state);
      case EditorTab.grid:
        return GridOverlay(state: state);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── ROI 박스 오버레이 ───────────────────────────────────────────────────────
// roiPosition: 화면 좌표 기준, InteractiveViewer 변환과 무관하게 자유 이동
class RoiPaintOverlay extends StatelessWidget {
  final ImageEditorState state;

  const RoiPaintOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: state.roiPosition.dx,
          top: state.roiPosition.dy,
          child: GestureDetector(
            onPanUpdate: (d) {
              // 배율이 바뀐 상태에서도 박스가 손가락을 정확히 따라옵니다.
              state.updateRoi(state.roiPosition + (d.delta));
            },
            child: Container(
              width: state.roiSize, // 3. 박스 크기도 스케일에 맞춰 시각적으로 유지
              height: state.roiSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent, width: 2),
                color: Colors.cyanAccent.withOpacity(0.1),
              ),
              child: const Center(
                child: Icon(
                  Icons.open_with,
                  color: Colors.cyanAccent,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 그리드 오버레이 ─────────────────────────────────────────────────────────
// InteractiveViewer의 변환 행렬을 Transform으로 직접 적용
// → 이미지와 완전히 동기화된 줌/패닝
class GridOverlay extends StatelessWidget {
  final ImageEditorState state;

  const GridOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state.controller,
      builder: (context, child) {
        final matrix = state.controller.value;
        final double currentScale = matrix.storage[0];
        return Center(
          child: SizedBox(
            width: state.drawW,
            height: state.drawH,
            child: CustomPaint(
              painter: CenterBaseSquareGridPainter(
                divisions: state.gridDivisions,
                isWidthBase: state.gridWidthBase,
                lineColor: state.gridColor,
                strokeWidth: 1.0 / currentScale,
                showGrid: state.showGrid,
              ),
            ),
          ),
        );
      },
    );
  }
}
