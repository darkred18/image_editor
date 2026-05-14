import 'package:flutter/material.dart';
import 'package:image_editor/overlays/overlays.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';

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

        minScale: 1,
        maxScale: 20,

        clipBehavior: Clip.none,

        onInteractionUpdate: (_) {
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

              if (state.tabIndex == 1 && state.showGrid)
                Positioned.fill(child: GridOverlay(state: state)),
            ],
          ),
        ),
      ),
    );
  }
}
