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
      alignment: Alignment.center,
      maxScale: 20,
      minScale: 1,
      clipBehavior: Clip.none,
      onInteractionUpdate: (_) {
        state.handleZoomChange();
        onInteraction?.call();
      },
      // drawW×drawH 정확한 크기로 이미지 렌더링
      // → imageOffsetX/Y가 InteractiveViewer 내부 레터박스 없이 0에 가까워짐
      // → 그리드/ROI 오버레이 좌표와 정확히 일치
      child: Center(
        child: SizedBox(
          width: state.drawW,
          height: state.drawH,
          child: Image.memory(
            state.imageBytes,
            fit: BoxFit.fill, // drawW×drawH에 정확히 맞춤
          ),
        ),
      ),
    );
  }
}
