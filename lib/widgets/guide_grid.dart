import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// class GridEditorPage extends StatefulWidget {
//   const GridEditorPage({super.key, required this.imageBytes});
//   final Uint8List imageBytes;

//   @override
//   State<GridEditorPage> createState() => _GridEditorPageState();
// }

// class _GridEditorPageState extends State<GridEditorPage> {
//   // 그리드 상태 변수
//   int _rows = 3;
//   int _columns = 3;
//   bool _showGrid = false;
//   double _strokeWidth = 1.0;
//   Color _lineColor = Colors.white70;

//   bool _isSquare = true;
//   int _divisions = 5;
//   bool _isWidthBase = true; // 기본 가로 기준
//   bool _isPanelOpen = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black, // 유화 집중도를 위한 다크 배경
//       appBar: AppBar(
//         title: const Text("구도 가이드 설정", style: TextStyle(fontSize: 18)),
//         // backgroundColor: Colors.black,
//         actions: [
//           IconButton(
//             icon: Icon(_showGrid ? Icons.visibility : Icons.visibility_off),
//             onPressed: () => setState(() => _showGrid = !_showGrid),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // [상단 이미지 영역] 패널이 올라오면 자동으로 크기가 조절됨
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(20),
//               alignment: Alignment.center,
//               child: Stack(
//                 children: [
//                   // 1. 원본 이미지 레이어
//                   Positioned.fill(
//                     child: ClipRRect(
//                       child: Image.memory(
//                         widget.imageBytes, // Uint8List 데이터
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                   ),
//                   // 2. 그리드 페인터 레이어
//                   Positioned.fill(
//                     child: _isSquare
//                         ?
//                           // 정방형 그리드
//                           // AspectRatio(
//                           //   aspectRatio: 1.0, // 실제 이미지의 비율 데이터가 있다면 그 값을 넣으세요
//                           //   child: CustomPaint(
//                           //     painter: SquareGridPainter(
//                           //       divisions: _divisions,
//                           //       isWidthBase: _isWidthBase,
//                           //       lineColor: Colors.white70,
//                           //       strokeWidth: 1.0,
//                           //       showGrid: _showGrid,
//                           //     ),
//                           //   ),
//                           // )
//                           // 실제 이미지가 화면에서 차지하는 크기를 계산하는 간단한 방법
// Center(
//   child: AspectRatio(
//     aspectRatio: imageWidth / imageHeight, // 실제 이미지의 가로세로 비율
//     child: Stack(
//       children: [
//         Positioned.fill(child: Image.memory(_imageBytes!, fit: BoxFit.fill)),
//         Positioned.fill(
//           child: CustomPaint(
//             painter: CenterBaseSquareGridPainter(
//               divisions: _divisions,
//               isWidthBase: _isWidthBase,
//               lineColor: Colors.white70,
//               strokeWidth: 1.0,
//               showGrid: _showGrid,
//             ),
//           ),
//         ),
//       ],
//     ),
//   ),
// )
//                         : CustomPaint(
//                             painter: GridPainter(
//                               rows: _rows,
//                               columns: _columns,
//                               lineColor: _lineColor,
//                               strokeWidth: _strokeWidth,
//                               showGrid: _showGrid,
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // [하단 조절 패널] 애니메이션 처리
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             height: _isPanelOpen ? 220 : 0,
//             curve: Curves.easeOutCubic,
//             decoration: BoxDecoration(
//               color: Colors.grey[900]?.withOpacity(0.9),
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(24),
//               ),
//               border: Border.all(color: Colors.white10),
//             ),
//             child: SingleChildScrollView(
//               child: _isSquare
//                   ? _buildSquareControlPanel()
//                   : _buildControlPanel(),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: _buildBottomBar(),
//     );
//   }

//   Widget _buildSquareControlPanel() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text("기준: ", style: TextStyle(color: Colors.white)),
//             ChoiceChip(
//               label: const Text("가로"),
//               selected: _isWidthBase,
//               onSelected: (val) => setState(() => _isWidthBase = true),
//             ),
//             const SizedBox(width: 10),
//             ChoiceChip(
//               label: const Text("세로"),
//               selected: !_isWidthBase,
//               onSelected: (val) => setState(() => _isWidthBase = false),
//             ),
//           ],
//         ),
//         Slider(
//           value: _divisions.toDouble(),
//           min: 2,
//           max: 20,
//           divisions: 18,
//           label: "$_divisions 칸",
//           onChanged: (v) => setState(() => _divisions = v.toInt()),
//         ),
//       ],
//     );
//   }

//   Widget _buildControlPanel() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
//       child: Column(
//         children: [
//           _buildSlider("가로 칸 수 (Columns)", _columns.toDouble(), 2, 10, (v) {
//             setState(() => _columns = v.toInt());
//           }),
//           _buildSlider("세로 칸 수 (Rows)", _rows.toDouble(), 2, 10, (v) {
//             setState(() => _rows = v.toInt());
//           }),
//           _buildSlider("선 두께 (Width)", _strokeWidth, 0.5, 5.0, (v) {
//             setState(() => _strokeWidth = v);
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildSlider(
//     String label,
//     double value,
//     double min,
//     double max,
//     Function(double) onChanged,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "$label: ${value.toStringAsFixed(value == value.toInt() ? 0 : 1)}",
//           style: const TextStyle(color: Colors.white70, fontSize: 13),
//         ),
//         Slider(
//           value: value,
//           min: min,
//           max: max,
//           activeColor: Colors.blueAccent,
//           inactiveColor: Colors.white10,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }

//   Widget _buildBottomBar() {
//     return BottomAppBar(
//       color: Colors.black,
//       height: 70,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _isPanelOpen
//                   ? Colors.blueAccent
//                   : Colors.grey[800],
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//             ),
//             icon: const Icon(Icons.tune, size: 20),
//             label: Text(_isPanelOpen ? "닫기" : "그리드 설정"),
//             onPressed: () {
//               setState(() {
//                 _isPanelOpen = !_isPanelOpen;
//                 if (_isPanelOpen) _showGrid = true; // 설정 창 열 때 그리드 자동 켬
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

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
                                    lineColor: Colors.white60,
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

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
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
                  activeColor: Colors.blue.shade500,
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
}

// class _GridImageEditorState extends State<GridImageEditor> {
//   int rows = 3;
//   int columns = 3;
//   bool showGrid = true;
//   double strokeWidth = 1.5;
//   Color lineColor = Colors.white;

//   bool _isSliderVisible = false;
//   double _value = 50;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Grid Editor")),

//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: InteractiveViewer(
//                 minScale: 0.5,
//                 maxScale: 4.0,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     Image.memory(widget.imageBytes),
//                     CustomPaint(
//                       painter: GridPainter(
//                         rows: rows,
//                         columns: columns,
//                         strokeWidth: strokeWidth,
//                         lineColor: lineColor,
//                         showGrid: showGrid,
//                       ),
//                       child: Container(),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Bottom Options
//           Container(
//             padding: EdgeInsets.all(12),
//             color: Colors.black87,
//             child: Column(
//               children: [
//                 ElevatedButton(
//                   onPressed: _openBottomSheet,
//                   child: const Text("Open Bottom Sheet"),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     const Text(
//                       "Show Grid",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     Switch(
//                       value: showGrid,
//                       onChanged: (v) => setState(() => showGrid = v),
//                     ),
//                     const Text(
//                       "Thickness",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     Slider(
//                       value: strokeWidth,
//                       min: 0.5,
//                       max: 6.0,
//                       onChanged: (v) => setState(() => strokeWidth = v),
//                     ),
//                   ],
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     // DropdownButton<int>(
//                     //   value: rows,
//                     //   dropdownColor: Colors.black87,
//                     //   items: List.generate(12, (i) => i + 1)
//                     //       .map(
//                     //         (e) => DropdownMenuItem(
//                     //           value: e,
//                     //           child: Text(
//                     //             "$e",
//                     //             style: TextStyle(color: Colors.white),
//                     //           ),
//                     //         ),
//                     //       )
//                     //       .toList(),
//                     //   onChanged: (v) => setState(() => rows = v!),
//                     // ),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() => _isSliderVisible = !_isSliderVisible);
//                       },
//                       child: Text(
//                         _isSliderVisible ? 'Hide Slider' : 'Show Slider',
//                       ),
//                     ),

//                     /// 슬라이더 애니메이션 영역
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeOut,
//                       height: _isSliderVisible ? 80 : 0,
//                       child: _isSliderVisible
//                           ? Slider(
//                               value: _value,
//                               min: 0,
//                               max: 100,
//                               onChanged: (v) => setState(() => _value = v),
//                             )
//                           : null,
//                     ),
//                     DropdownButton<int>(
//                       value: columns,
//                       dropdownColor: Colors.black87,
//                       items: List.generate(12, (i) => i + 1)
//                           .map(
//                             (e) => DropdownMenuItem(
//                               value: e,
//                               child: Text(
//                                 "$e",
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: (v) => setState(() => columns = v!),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.color_lens, color: lineColor),
//                       onPressed: () async {
//                         final picked = await showDialog(
//                           context: context,
//                           builder: (_) => ColorPickerDialog(initial: lineColor),
//                         );
//                         if (picked != null) setState(() => lineColor = picked);
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   bool _useAdditionalGrids = false;
//   bool _isGridTypeExpanded = false;
//   bool _isGridColorExpanded = false;
//   int _rows = 7;
//   int _cols = 10;
//   double _r = 255;
//   double _g = 255;
//   double _b = 255;
//   double _a = 1.0;
//   double _lineWidth = 3.0;
//   bool _showDiagonal = false;
//   void _openBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       enableDrag: false,
//       builder: (context) {
//         double sheetHeightRatio = 0.5;

//         return StatefulBuilder(
//           builder: (context, setState) {
//             return Container(
//               height: MediaQuery.of(context).size.height * sheetHeightRatio,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: Column(
//                 children: [
//                   // Drag handle area only
//                   GestureDetector(
//                     behavior: HitTestBehavior.opaque,
//                     onVerticalDragUpdate: (details) {
//                       setState(() {
//                         sheetHeightRatio -=
//                             details.delta.dy /
//                             MediaQuery.of(context).size.height;
//                         sheetHeightRatio = sheetHeightRatio.clamp(0.2, 0.9);
//                       });
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 12,
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 40,
//                             height: 6,
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade500,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           const Spacer(),
//                           IconButton(
//                             icon: const Icon(Icons.close),
//                             onPressed: () => Navigator.pop(context),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const Divider(height: 1),

//                   Expanded(
//                     child: ListView(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       children: [
//                         SwitchListTile(
//                           title: const Text("Use Additional Grids"),
//                           value: _useAdditionalGrids,
//                           onChanged: (v) =>
//                               setState(() => _useAdditionalGrids = v),
//                         ),
//                         const Divider(),

//                         _buildSettingsSheet(),
//                         const Text("Line Width:"),
//                         Slider(
//                           min: 0.5,
//                           max: 10,
//                           value: _lineWidth.toDouble(),
//                           onChanged: (v) => setState(() => _lineWidth = v),
//                         ),
//                         SwitchListTile(
//                           title: const Text("Show Diagonal Lines"),
//                           value: _showDiagonal,
//                           onChanged: (v) => setState(() => _showDiagonal = v),
//                         ),
//                         ListTile(
//                           title: const Text("Templates"),
//                           trailing: const Icon(Icons.chevron_right),
//                         ),
//                         ListTile(
//                           title: const Text("More Settings"),
//                           trailing: const Icon(Icons.chevron_right),
//                         ),
//                         const SizedBox(height: 40),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildSettingsSheet() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: StatefulBuilder(
//         builder: (context, setState) {
//           return Column(
//             children: [
//               /// Grid Type Section
//               ExpansionTile(
//                 title: const Text("Grid Type"),
//                 initiallyExpanded: _isGridTypeExpanded,
//                 onExpansionChanged: (value) {
//                   setState(() => _isGridTypeExpanded = value);
//                 },
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text("row: $_rows"),

//                       Expanded(
//                         child: customSlider(
//                           min: 1,
//                           max: 15,
//                           value: _rows.toDouble(),
//                           onChanged: (v) => setState(() => _rows = v.toInt()),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text("col: $_cols"),
//                       Expanded(
//                         child: customSlider(
//                           min: 1,
//                           max: 15,
//                           value: _cols.toDouble(),
//                           onChanged: (v) => setState(() => _cols = v.toInt()),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),

//               /// Grid Color Section
//               ExpansionTile(
//                 title: const Text("Grid Color"),
//                 initiallyExpanded: _isGridColorExpanded,
//                 onExpansionChanged: (value) {
//                   setState(() => _isGridColorExpanded = value);
//                 },
//                 children: [
//                   customColorSlider(
//                     label: 'R',
//                     value: _r,
//                     color: Colors.red,
//                     onChanged: (v) => setState(() => _r = v),
//                   ),
//                   // _colorSlider(
//                   //   label: 'R',
//                   //   value: _r,
//                   //   color: Colors.red,
//                   //   onChanged: (v) => _r = v,
//                   // ),
//                   customColorSlider(
//                     label: 'G',
//                     value: _g,
//                     color: Colors.green,
//                     onChanged: (v) => setState(() => _g = v),
//                   ),
//                   customColorSlider(
//                     label: 'B',
//                     value: _b,
//                     color: Colors.blue,
//                     onChanged: (v) => setState(() => _b = v),
//                   ),
//                   customColorSlider(
//                     label: 'A',
//                     value: _a * 255,
//                     color: Colors.grey,
//                     onChanged: (v) => setState(() => _a = v / 255),
//                   ),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _colorSlider({
//     required String label,
//     required double value,
//     required Color color,
//     required ValueChanged<double> onChanged,
//   }) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text("$label: ${value.toInt()}"),
//         Expanded(
//           child: Slider(
//             value: value,
//             min: 0,
//             max: 255,
//             onChanged: (v) {
//               setState(() {
//                 onChanged(v); // 부모 쪽에서 value 갱신하도록
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   int opacity(double percent) => (percent * 255).toInt();

//   Widget customSlider({
//     double min = 0,
//     double max = 255,
//     required double value,
//     required ValueChanged<double> onChanged,
//     Color activeColor = Colors.blue,
//   }) {
//     return SliderTheme(
//       data: SliderThemeData(
//         trackHeight: 3, // 얇은 트랙
//         activeTrackColor: activeColor.withAlpha(opacity(0.8)),
//         inactiveTrackColor: activeColor.withAlpha(opacity(0.2)),

//         thumbShape: const RoundSliderThumbShape(
//           enabledThumbRadius: 8, // 작은 원 핸들
//         ),
//         thumbColor: activeColor,
//         overlayColor: activeColor.withAlpha(opacity(0.2)), // 터치 시 확장되는 영역
//         overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
//         trackShape: const RoundedRectSliderTrackShape(),
//       ),
//       child: Slider(min: min, max: max, value: value, onChanged: onChanged),
//     );
//   }
//   Widget customColorSlider({
//     required String label,
//     required Color color,
//     required double value,
//     required ValueChanged<double> onChanged,
//     Color activeColor = Colors.blue,
//     double min = 0,
//     double max = 255,
//   }) {
//     return Row(
//       children: [
//         SizedBox(
//           width: 50,
//           child: label == 'A'
//               ? Text("$label: ${(value / 255).toStringAsFixed(1)}")
//               : Text("$label: ${value.toInt()}"),
//         ),
//         Expanded(
//           child: SliderTheme(
//             data: SliderThemeData(
//               trackHeight: 3, // 얇은 트랙
//               activeTrackColor: activeColor.withAlpha(opacity(0.8)),
//               inactiveTrackColor: color.withAlpha(opacity((0.3))),

//               // inactiveTrackColor: Colors.grey.shade200,
//               thumbShape: const RoundSliderThumbShape(
//                 enabledThumbRadius: 8, // 작은 원 핸들
//               ),
//               thumbColor: activeColor,
//               overlayColor: activeColor.withAlpha(opacity(0.2)), // 터치 시 확장되는 영역
//               overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
//               trackShape: const RoundedRectSliderTrackShape(),
//             ),
//             child: Slider(
//               min: min,
//               max: max,
//               value: value,
//               activeColor: color,
//               onChanged: onChanged,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildColorSlider(
//     String label,
//     double value,
//     Color color,
//     Function(double) onChanged,
//   ) {
//     return Row(
//       children: [
//         SizedBox(width: 30, child: Text("$label: ${value.toInt()}")),
//         Expanded(
//           child: Slider(
//             min: 0,
//             max: 255,
//             value: value,
//             activeColor: color,
//             onChanged: (v) {
//               setState(() {
//                 value = v;
//                 onChanged(v);
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

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
