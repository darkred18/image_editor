import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class GridImageEditor extends StatefulWidget {
  final Uint8List imageBytes;
  const GridImageEditor({super.key, required this.imageBytes});

  @override
  State<GridImageEditor> createState() => _GridImageEditorState();
}

class _GridImageEditorState extends State<GridImageEditor> {
  int rows = 3;
  int columns = 3;
  bool showGrid = true;
  double strokeWidth = 1.5;
  Color lineColor = Colors.white;

  bool _isSliderVisible = false;
  double _value = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Grid Editor")),

      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.memory(widget.imageBytes),
                    CustomPaint(
                      painter: GridPainter(
                        rows: rows,
                        columns: columns,
                        strokeWidth: strokeWidth,
                        lineColor: lineColor,
                        showGrid: showGrid,
                      ),
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Options
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.black87,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _openBottomSheet,
                  child: const Text("Open Bottom Sheet"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      "Show Grid",
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      value: showGrid,
                      onChanged: (v) => setState(() => showGrid = v),
                    ),
                    const Text(
                      "Thickness",
                      style: TextStyle(color: Colors.white),
                    ),
                    Slider(
                      value: strokeWidth,
                      min: 0.5,
                      max: 6.0,
                      onChanged: (v) => setState(() => strokeWidth = v),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // DropdownButton<int>(
                    //   value: rows,
                    //   dropdownColor: Colors.black87,
                    //   items: List.generate(12, (i) => i + 1)
                    //       .map(
                    //         (e) => DropdownMenuItem(
                    //           value: e,
                    //           child: Text(
                    //             "$e",
                    //             style: TextStyle(color: Colors.white),
                    //           ),
                    //         ),
                    //       )
                    //       .toList(),
                    //   onChanged: (v) => setState(() => rows = v!),
                    // ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _isSliderVisible = !_isSliderVisible);
                      },
                      child: Text(
                        _isSliderVisible ? 'Hide Slider' : 'Show Slider',
                      ),
                    ),

                    /// 슬라이더 애니메이션 영역
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      height: _isSliderVisible ? 80 : 0,
                      child: _isSliderVisible
                          ? Slider(
                              value: _value,
                              min: 0,
                              max: 100,
                              onChanged: (v) => setState(() => _value = v),
                            )
                          : null,
                    ),
                    DropdownButton<int>(
                      value: columns,
                      dropdownColor: Colors.black87,
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                "$e",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => columns = v!),
                    ),
                    IconButton(
                      icon: Icon(Icons.color_lens, color: lineColor),
                      onPressed: () async {
                        final picked = await showDialog(
                          context: context,
                          builder: (_) => ColorPickerDialog(initial: lineColor),
                        );
                        if (picked != null) setState(() => lineColor = picked);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _useAdditionalGrids = false;
  bool _isGridTypeExpanded = false;
  bool _isGridColorExpanded = false;
  int _rows = 7;
  int _cols = 10;

  double _r = 255;
  double _g = 255;
  double _b = 255;
  double _a = 1.0;

  double _lineWidth = 3.0;
  bool _showDiagonal = false;

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) {
        double sheetHeightRatio = 0.5;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * sheetHeightRatio,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle area only
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        sheetHeightRatio -=
                            details.delta.dy /
                            MediaQuery.of(context).size.height;
                        sheetHeightRatio = sheetHeightRatio.clamp(0.2, 0.9);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade500,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        SwitchListTile(
                          title: const Text("Use Additional Grids"),
                          value: _useAdditionalGrids,
                          onChanged: (v) =>
                              setState(() => _useAdditionalGrids = v),
                        ),
                        const Divider(),

                        _buildSettingsSheet(),

                        const Text("Line Width:"),
                        Slider(
                          min: 0.5,
                          max: 10,
                          value: _lineWidth.toDouble(),
                          onChanged: (v) => setState(() => _lineWidth = v),
                        ),

                        SwitchListTile(
                          title: const Text("Show Diagonal Lines"),
                          value: _showDiagonal,
                          onChanged: (v) => setState(() => _showDiagonal = v),
                        ),

                        ListTile(
                          title: const Text("Templates"),
                          trailing: const Icon(Icons.chevron_right),
                        ),

                        ListTile(
                          title: const Text("More Settings"),
                          trailing: const Icon(Icons.chevron_right),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsSheet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              /// Grid Type Section
              ExpansionTile(
                title: const Text("Grid Type"),
                initiallyExpanded: _isGridTypeExpanded,
                onExpansionChanged: (value) {
                  setState(() => _isGridTypeExpanded = value);
                },
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("row: $_rows"),

                      Expanded(
                        child: customSlider(
                          min: 1,
                          max: 15,
                          value: _rows.toDouble(),
                          onChanged: (v) => setState(() => _rows = v.toInt()),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("col: $_cols"),
                      Expanded(
                        child: customSlider(
                          min: 1,
                          max: 15,
                          value: _cols.toDouble(),
                          onChanged: (v) => setState(() => _cols = v.toInt()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /// Grid Color Section
              ExpansionTile(
                title: const Text("Grid Color"),
                initiallyExpanded: _isGridColorExpanded,
                onExpansionChanged: (value) {
                  setState(() => _isGridColorExpanded = value);
                },
                children: [
                  customColorSlider(
                    label: 'R',
                    value: _r,
                    color: Colors.red,
                    onChanged: (v) => setState(() => _r = v),
                  ),
                  // _colorSlider(
                  //   label: 'R',
                  //   value: _r,
                  //   color: Colors.red,
                  //   onChanged: (v) => _r = v,
                  // ),
                  customColorSlider(
                    label: 'G',
                    value: _g,
                    color: Colors.green,
                    onChanged: (v) => setState(() => _g = v),
                  ),
                  customColorSlider(
                    label: 'B',
                    value: _b,
                    color: Colors.blue,
                    onChanged: (v) => setState(() => _b = v),
                  ),
                  customColorSlider(
                    label: 'A',
                    value: _a * 255,
                    color: Colors.grey,
                    onChanged: (v) => setState(() => _a = v / 255),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _colorSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label: ${value.toInt()}"),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            onChanged: (v) {
              setState(() {
                onChanged(v); // 부모 쪽에서 value 갱신하도록
              });
            },
          ),
        ),
      ],
    );
  }

  int opacity(double percent) => (percent * 255).toInt();

  Widget customSlider({
    double min = 0,
    double max = 255,
    required double value,
    required ValueChanged<double> onChanged,
    Color activeColor = Colors.blue,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3, // 얇은 트랙
        activeTrackColor: activeColor.withAlpha(opacity(0.8)),
        inactiveTrackColor: activeColor.withAlpha(opacity(0.2)),

        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 8, // 작은 원 핸들
        ),
        thumbColor: activeColor,
        overlayColor: activeColor.withAlpha(opacity(0.2)), // 터치 시 확장되는 영역
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(min: min, max: max, value: value, onChanged: onChanged),
    );
  }

  Widget customColorSlider({
    required String label,
    required Color color,
    required double value,
    required ValueChanged<double> onChanged,
    Color activeColor = Colors.blue,
    double min = 0,
    double max = 255,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: label == 'A'
              ? Text("$label: ${(value / 255).toStringAsFixed(1)}")
              : Text("$label: ${value.toInt()}"),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3, // 얇은 트랙
              activeTrackColor: activeColor.withAlpha(opacity(0.8)),
              inactiveTrackColor: color.withAlpha(opacity((0.3))),

              // inactiveTrackColor: Colors.grey.shade200,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8, // 작은 원 핸들
              ),
              thumbColor: activeColor,
              overlayColor: activeColor.withAlpha(opacity(0.2)), // 터치 시 확장되는 영역
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              min: min,
              max: max,
              value: value,
              activeColor: color,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSlider(
    String label,
    double value,
    Color color,
    Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 30, child: Text("$label: ${value.toInt()}")),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            value: value,
            activeColor: color,
            onChanged: (v) {
              setState(() {
                value = v;
                onChanged(v);
              });
            },
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final int rows;
  final int columns;
  final Color lineColor;
  final double strokeWidth;
  final bool showGrid;

  GridPainter({
    required this.rows,
    required this.columns,
    required this.lineColor,
    required this.strokeWidth,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth;

    final dashedPaint = Paint()
      ..color = lineColor.withOpacity(0.6)
      ..strokeWidth = strokeWidth / 2;

    final rowHeight = size.height / rows;
    final colWidth = size.width / columns;

    // solid lines
    for (int i = 1; i < rows; i++) {
      canvas.drawLine(
        Offset(0, i * rowHeight),
        Offset(size.width, i * rowHeight),
        paint,
      );
    }

    for (int i = 1; i < columns; i++) {
      canvas.drawLine(
        Offset(i * colWidth, 0),
        Offset(i * colWidth, size.height),
        paint,
      );
    }

    // dashed middle lines
    drawDashedLine(
      canvas,
      dashedPaint,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
    ); // center v
    drawDashedLine(
      canvas,
      dashedPaint,
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
    ); // center h
  }

  void drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const dashWidth = 5;
    const dashSpace = 5;

    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double distance = sqrt(dx * dx + dy * dy);
    double dashCount = distance / (dashWidth + dashSpace);

    double progress = 0;

    for (int i = 0; i < dashCount; ++i) {
      final x1 = start.dx + (dx * progress / distance);
      final y1 = start.dy + (dy * progress / distance);
      progress += dashWidth;
      final x2 = start.dx + (dx * progress / distance);
      final y2 = start.dy + (dy * progress / distance);
      progress += dashSpace;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ColorPickerDialog extends StatelessWidget {
  final Color initial;
  const ColorPickerDialog({super.key, required this.initial});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
    ];
    return AlertDialog(
      title: Text("Pick Line Color"),
      content: Wrap(
        children: colors
            .map(
              (c) => GestureDetector(
                onTap: () => Navigator.pop(context, c),
                child: Container(
                  margin: EdgeInsets.all(6),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
