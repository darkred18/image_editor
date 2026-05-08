import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';

// 2. 그리드 에디터 페이지 위젯
class GridEditorPage extends StatefulWidget {
  final Uint8List imageBytes;

  const GridEditorPage({super.key, required this.imageBytes});

  @override
  State<GridEditorPage> createState() => _GridEditorPageState();
}

class _GridEditorPageState extends State<GridEditorPage> {
  int _divisions = 4;
  bool _isWidthBase = true;
  bool _showGrid = true;
  bool _isPanelOpen = false;
  double _aspectRatio = 1.0;
  bool _isLoaded = false;

  Color _lineColor = Colors.white60; // 기본값
  // 추천 팔레트 리스트
  final List<Color> _palette = [
    Colors.white60,
    Colors.black54,
    Colors.redAccent,
    Colors.yellowAccent,
    Colors.cyanAccent,
    Colors.lightGreenAccent,
  ];

  @override
  void initState() {
    super.initState();
    _calculateImageSize();
  }

  // 이미지 원본 비율 계산
  Future<void> _calculateImageSize() async {
    final ui.Image image = await decodeImageFromList(widget.imageBytes);
    if (mounted) {
      setState(() {
        _aspectRatio = image.width / image.height;
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("유화 구도 가이드", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.blueGrey.shade400,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 상단 이미지 영역 (자동 리사이징)
          Expanded(
            child: _isLoaded
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      // 화면 제약 조건 내에서 이미지가 차지할 실제 크기 계산 (BoxFit.contain 로직)
                      double availWidth = constraints.maxWidth;
                      double availHeight = constraints.maxHeight;
                      double actualWidth, actualHeight;

                      if (availWidth / availHeight > _aspectRatio) {
                        actualHeight = availHeight;
                        actualWidth = availHeight * _aspectRatio;
                      } else {
                        actualWidth = availWidth;
                        actualHeight = availWidth / _aspectRatio;
                      }

                      return Center(
                        child: SizedBox(
                          width: actualWidth,
                          height: actualHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.memory(
                                  widget.imageBytes,
                                  fit: BoxFit.fill,
                                  gaplessPlayback: true,
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: CenterBaseSquareGridPainter(
                                    divisions: _divisions,
                                    isWidthBase: _isWidthBase,
                                    lineColor: _lineColor,
                                    strokeWidth: 1.0,
                                    showGrid: _showGrid,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          // 하단 조절 패널 (애니메이션)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isPanelOpen ? 200 : 0,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade800,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(child: _buildControlPanel()),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      children: [
        const Text("선 색상", style: TextStyle(color: Colors.white70)),
        const SizedBox(width: 15),
        // Row 안에서 ListView를 쓸 때는 ListView를 Expanded로 감싸야 합니다.
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _palette.length,
              itemBuilder: (context, index) {
                // 위에서 수정한 고정 크기 Container 코드 삽입
                return _buildColorItem(index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildColorPicker(), // 색상 선택기 추가
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("기준 방향", style: TextStyle(color: Colors.white70)),
              ToggleButtons(
                isSelected: [_isWidthBase, !_isWidthBase],
                onPressed: (index) => setState(() => _isWidthBase = index == 0),
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minWidth: 60, minHeight: 32),
                selectedColor: Colors.white,
                borderColor: Colors.blueGrey,
                color: Colors.grey,
                fillColor: Colors.blueGrey,

                children: const [Text("가로"), Text("세로")],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text("분할", style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  activeColor: _lineColor.withAlpha(200), // 선택된 선 색상을 슬라이더에 반영
                  inactiveColor: Colors.grey,
                  thumbColor: Colors.blue,
                  value: _divisions.toDouble(),
                  min: 2,
                  max: 20,
                  divisions: 18,
                  // label: "$_divisions 칸",
                  onChanged: (v) => setState(() => _divisions = v.toInt()),
                ),
              ),
              Text("$_divisions", style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: Colors.blueGrey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              _showGrid ? Icons.grid_on : Icons.grid_off,
              color: _showGrid ? Colors.white54 : Colors.blueGrey.shade900,
            ),
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _isPanelOpen ? Colors.white54 : Colors.blueGrey.shade900,
            ),
            onPressed: () => setState(() => _isPanelOpen = !_isPanelOpen),
          ),
        ],
      ),
    );
  }

  Widget _buildColorItem(int index) {
    bool isSelected = _lineColor == _palette[index];
    return GestureDetector(
      onTap: () => setState(() => _lineColor = _palette[index]),
      child: Container(
        // Expanded를 빼고 Container만 사용하세요
        margin: const EdgeInsets.only(right: 10),
        width: 35, // 여기서 고정 너비를 주었으므로 이미 충분합니다
        height: 35,
        decoration: BoxDecoration(
          color: _palette[index],
          shape: BoxShape.circle, // 유화 앱에 어울리는 원형 버튼
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

// 1. 중앙 기준 정방형 그리드 페인터
class CenterBaseSquareGridPainter extends CustomPainter {
  final int divisions;
  final bool isWidthBase;
  final Color lineColor;
  final double strokeWidth;
  final bool showGrid;

  CenterBaseSquareGridPainter({
    required this.divisions,
    required this.isWidthBase,
    required this.lineColor,
    required this.strokeWidth,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid || divisions <= 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth;

    double centerX = size.width / 2;
    double centerY = size.height / 2;

    // 기준축에 따른 정사각형 한 변(step) 계산
    double step = isWidthBase
        ? size.width / divisions
        : size.height / divisions;

    // 세로선 (중앙에서 좌우로)
    for (double x = centerX; x <= size.width + 0.1; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double x = centerX - step; x >= -0.1; x -= step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 가로선 (중앙에서 상하로)
    for (double y = centerY; y <= size.height + 0.1; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double y = centerY - step; y >= -0.1; y -= step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 중앙 십자선 강조
    final centerPaint = Paint()
      ..color = lineColor.withOpacity(0.8)
      ..strokeWidth = strokeWidth * 2;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      centerPaint,
    );
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CenterBaseSquareGridPainter oldDelegate) => true;
}

class SquareGridPainter extends CustomPainter {
  final int divisions; // 기준 방향을 몇 칸으로 나눌 것인가
  final bool isWidthBase; // true: 가로 기준, false: 세로 기준
  final Color lineColor;
  final double strokeWidth;
  final bool showGrid;

  SquareGridPainter({
    required this.divisions,
    required this.isWidthBase,
    required this.lineColor,
    required this.strokeWidth,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid || divisions <= 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth;

    // 1. 정사각형 한 변의 길이(step) 계산
    double step = isWidthBase
        ? size.width / divisions
        : size.height / divisions;

    // 2. 세로선 그리기 (가로축으로 이동하며)
    for (double x = 0; x <= size.width + 0.1; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 3. 가로선 그리기 (세로축으로 이동하며)
    for (double y = 0; y <= size.height + 0.1; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SquareGridPainter oldDelegate) => true;
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
