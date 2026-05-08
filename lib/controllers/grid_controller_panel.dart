import 'package:flutter/material.dart';

class GridControlPanel extends StatelessWidget {
  final int divisions;
  final bool isWidthBase;
  final bool showGrid;
  final Color lineColor;

  final ValueChanged<int> onDivisionsChanged;
  final ValueChanged<bool> onWidthBaseChanged;
  final ValueChanged<bool> onShowGridChanged;
  final ValueChanged<Color> onColorChanged;

  const GridControlPanel({
    super.key,
    required this.divisions,
    required this.isWidthBase,
    required this.showGrid,
    required this.lineColor,
    required this.onDivisionsChanged,
    required this.onWidthBaseChanged,
    required this.onShowGridChanged,
    required this.onColorChanged,
  });

  static const List<Color> _palette = [
    Colors.white60,
    Colors.black54,
    Colors.redAccent,
    Colors.yellowAccent,
    Colors.cyanAccent,
    Colors.lightGreenAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            //--------------------------------
            // 색상 선택
            //--------------------------------
            Row(
              children: [
                const Text("선 색상", style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _palette.length,
                      itemBuilder: (context, index) {
                        final color = _palette[index];
                        final isSelected = color == lineColor;

                        return GestureDetector(
                          onTap: () => onColorChanged(color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white24,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            //--------------------------------
            // 가로 / 세로 기준
            //--------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("기준 방향", style: TextStyle(color: Colors.white70)),
                ToggleButtons(
                  isSelected: [isWidthBase, !isWidthBase],
                  onPressed: (index) => onWidthBaseChanged(index == 0),
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(
                    minWidth: 60,
                    minHeight: 32,
                  ),
                  selectedColor: Colors.white,
                  borderColor: Colors.blueGrey,
                  color: Colors.grey,
                  fillColor: Colors.blueGrey,
                  children: const [Text("가로"), Text("세로")],
                ),
              ],
            ),

            const SizedBox(height: 20),

            //--------------------------------
            // 분할 수
            //--------------------------------
            Row(
              children: [
                const Text("분할", style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    activeColor: lineColor.withAlpha(200),
                    inactiveColor: Colors.grey,
                    thumbColor: Colors.blue,
                    value: divisions.toDouble(),
                    min: 2,
                    max: 20,
                    divisions: 18,
                    onChanged: (v) => onDivisionsChanged(v.toInt()),
                  ),
                ),
                Text("$divisions", style: const TextStyle(color: Colors.white)),
              ],
            ),

            //--------------------------------
            // Grid ON/OFF
            //--------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("그리드 표시", style: TextStyle(color: Colors.white70)),
                Switch(
                  value: showGrid,
                  onChanged: onShowGridChanged,
                  activeColor: lineColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
