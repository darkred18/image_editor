import 'package:flutter/material.dart';
import 'package:image_editor/overlays/overlays.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';
import 'package:image_editor/screens/edit_screen.dart';

class CanvasCore extends StatelessWidget {
  final ImageEditorState state;
  final VoidCallback? onInteraction;

  const CanvasCore({super.key, required this.state, this.onInteraction});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        transformationController: state.controller,

        alignment: Alignment.topLeft,

        constrained: false,

        boundaryMargin: EdgeInsets.zero,

        minScale: state.minScale, // 동적으로
        maxScale: 20,

        clipBehavior: Clip.none,

        onInteractionUpdate: (_) {
          _clampMatrix();
          state.handleZoomChange();
          state.updateRoiAnalysis();
          onInteraction?.call();
        },
        onInteractionEnd: (_) {
          state.updateRoiAnalysis();
        },

        child: SizedBox(
          width: state.drawW,
          height: state.drawH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.memory(state.imageBytes, fit: BoxFit.fill),
              ),

              if (state.tabIndex == EditorTab.grid && state.showGrid)
                Positioned.fill(child: GridOverlay(state: state)),
            ],
          ),
        ),
      ),
    );
  }

  void _clampMatrix() {
    final matrix = state.controller.value;
    final double scale = matrix.getMaxScaleOnAxis();
    double tx = matrix.getTranslation().x;
    double ty = matrix.getTranslation().y;

    final scaledW = state.drawW * scale;
    final scaledH = state.drawH * scale;

    tx = tx.clamp(
      -(scaledW - state.viewportSize.width).clamp(0.0, double.infinity),
      0.0,
    );
    ty = ty.clamp(
      -(scaledH - state.viewportSize.height).clamp(0.0, double.infinity),
      0.0,
    );

    if (tx != matrix.getTranslation().x || ty != matrix.getTranslation().y) {
      state.controller.value = Matrix4.diagonal3Values(scale, scale, 1.0)
        ..setTranslationRaw(tx, ty, 0);
    }
  }
}
