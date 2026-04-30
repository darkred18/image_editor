import 'package:flutter/material.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';

class CanvasCore extends StatelessWidget {
  final ImageEditorState state;
  final VoidCallback? onInteraction;

  const CanvasCore({super.key, required this.state, this.onInteraction});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: state.controller,
      maxScale: 20,
      minScale: 1,
      clipBehavior: Clip.none,
      //줌/팬 할 때 ROI 다시 계산
      onInteractionUpdate: (_) {
        onInteraction?.call(); // ROI 계산 트리거
      },
      child: Center(
        child: SizedBox(
          width: state.drawW,
          height: state.drawH,
          child: Image.memory(state.imageBytes, fit: BoxFit.fill),
        ),
      ),
    );
  }
}
