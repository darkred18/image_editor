import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';
import 'package:image_editor/widgets/guide_grid.dart';

class GridImageView extends StatelessWidget {
  final ImageEditorState state;

  const GridImageView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(state.imageBytes, fit: BoxFit.contain),
        CustomPaint(
          painter: CenterBaseSquareGridPainter(
            divisions: state.gridDivisions,
            isWidthBase: state.gridWidthBase,
            lineColor: state.gridColor,
            strokeWidth: 1.0,
            showGrid: state.showGrid,
          ),
        ),
      ],
    );
  }
}
