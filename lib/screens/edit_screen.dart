import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:image_editor/models/size_model.dart';

class CanvasSizeEdit {
  final double width;
  final double height;
  final double ratio;

  CanvasSizeEdit({
    required this.width,
    required this.height,
    required this.ratio,
  });

  factory CanvasSizeEdit.fromJson(Map<String, dynamic> json) {
    return CanvasSizeEdit(
      width: json['width'],
      height: json['height'],
      ratio: json['ratio'],
    );
  }
}

class ImageEditorPage extends StatefulWidget {
  final Uint8List imageBytes;
  const ImageEditorPage({super.key, required this.imageBytes});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  final editorKey = GlobalKey<ExtendedImageEditorState>();

  bool cropMode = false;
  double? _aspectRatio;

  // 현재 선택값
  String selectedType = "F";
  String selectedHo = "1";
  // int selectedHo = 6;

  bool isPickerOpen = false;
  double pickerHeight = 60; // 기본 버튼 높이

  late dynamic canvasSize;

  // // 호수별 실제 mm 데이터 (요약 버전)
  // final Map<String, Map<int, Size>> canvasSize = {
  //   "F": {
  //     0: Size(180, 140),
  //     1: Size(220, 160),
  //     2: Size(270, 190),
  //     3: Size(330, 220),
  //     4: Size(380, 270),
  //     5: Size(410, 318),
  //     6: Size(410, 318),
  //     8: Size(455, 379),
  //     10: Size(530, 455),
  //     12: Size(606, 500),
  //     15: Size(652, 530),
  //     20: Size(727, 606),
  //     30: Size(910, 727),
  //     40: Size(1000, 803),
  //     50: Size(1167, 910),
  //     60: Size(1303, 970),
  //     80: Size(1455, 1121),
  //     100: Size(1620, 1303),
  //   },
  //   "M": {
  //     0: Size(180, 100),
  //     1: Size(220, 120),
  //     2: Size(270, 140),
  //     3: Size(330, 160),
  //     4: Size(380, 200),
  //     5: Size(410, 220),
  //     6: Size(410, 243),
  //     8: Size(455, 273),
  //     10: Size(530, 333),
  //   },
  //   "P": {
  //     0: Size(180, 120),
  //     1: Size(220, 140),
  //     2: Size(270, 160),
  //     3: Size(330, 190),
  //     4: Size(380, 220),
  //     5: Size(410, 243),
  //     6: Size(410, 273),
  //     8: Size(455, 303),
  //     10: Size(530, 379),
  //   },
  // };

  @override
  void initState() {
    super.initState();
    loadSizes();
  }

  void loadSizes() async {
    // <String, Map<String, CanvasSize>>
    canvasSize = await loadCanvasSizes();

    print(canvasSize["F"]?["1"]?.width); // 22.7
    print(canvasSize["F"]?["1"]?.height); // 15.8
    print(canvasSize["F"]?["1"]?.ratio); // 1.4367
  }

  Future<Map<String, Map<String, CanvasSizeEdit>>> loadCanvasSizes() async {
    final jsonString = await rootBundle.loadString('assets/canvas_size.json');
    final Map<String, dynamic> raw = jsonDecode(jsonString);

    final result = <String, Map<String, CanvasSizeEdit>>{};

    raw.forEach((category, items) {
      final innerMap = <String, CanvasSizeEdit>{};

      (items as Map<String, dynamic>).forEach((key, value) {
        innerMap[key] = CanvasSizeEdit.fromJson(value);
      });

      result[category] = innerMap;
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 이미지
          Positioned.fill(
            child: ExtendedImage.memory(
              widget.imageBytes,
              mode: ExtendedImageMode.editor,
              extendedImageEditorKey: editorKey,
              fit: BoxFit.contain,
              initGestureConfigHandler: (state) {
                return GestureConfig(
                  minScale: 0.8,
                  maxScale: 8.0,
                  initialScale: 1.0,
                  inPageView: false, // 페이지 슬라이드와의 충돌 방지 옵션
                  // hitTestBehavior: HitTestBehavior.deferToChild,
                );
              },
              initEditorConfigHandler: (state) {
                return EditorConfig(
                  cropAspectRatio: _aspectRatio,
                  maxScale: 8.0,
                  // enableGestureRotate: true,
                );
              },
            ),
          ),

          // 상단바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _topButton("취소", () {
                    if (cropMode) {
                      setState(() => cropMode = false);
                    } else {
                      Navigator.pop(context);
                    }
                  }),
                  _topButton("완료", _finishEditing),
                ],
              ),
            ),
          ),

          // 항상 고정된 바텀바
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),

          // 오버레이(크롭 모드 UI)
          if (cropMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: _buildCropOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _topButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(fontSize: 17)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.black.withOpacity(0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomIcon(Icons.crop, () => setState(() => cropMode = true)),
            _bottomIcon(Icons.info_outline, () {}),
            _bottomIcon(Icons.rotate_right, () {}),
          ],
        ),
      ),
    );
  }

  Widget _bottomIcon(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(icon, size: 28, color: Colors.white),
    );
  }

  // // 🔥 F/M/P + 호수 드롭다운 overlay
  // Widget _buildCropOverlay() {
  //   return AnimatedOpacity(
  //     opacity: cropMode ? 1 : 0,
  //     duration: const Duration(milliseconds: 200),
  //     child: Container(
  //       padding: const EdgeInsets.all(14),
  //       margin: const EdgeInsets.symmetric(horizontal: 16),
  //       decoration: BoxDecoration(
  //         color: Colors.black.withOpacity(0.55),
  //         borderRadius: BorderRadius.circular(20),
  //       ),
  //       child: Column(
  //         children: [
  //           // F M P 선택
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: [_typeButton("F"), _typeButton("M"), _typeButton("P")],
  //           ),
  //           const SizedBox(height: 12),

  //           // 호 선택 dropdown
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               DropdownButton<int>(
  //                 dropdownColor: Colors.black87,
  //                 value: selectedHo,
  //                 underline: SizedBox(),
  //                 style: TextStyle(color: Colors.white),
  //                 items: canvasSize[selectedType]!.keys.map((ho) {
  //                   return DropdownMenuItem(value: ho, child: Text("$ho호"));
  //                 }).toList(),
  //                 onChanged: (ho) {
  //                   setState(() {
  //                     selectedHo = ho!;
  //                     _applyCanvasRatio();
  //                   });
  //                 },
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _buildCropOverlay() {
    return AnimatedOpacity(
      opacity: cropMode ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        // decoration: BoxDecoration(
        //   color: Colors.black.withAlpha(140),
        //   borderRadius: BorderRadius.circular(20),
        // ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // _typeButton("F"),
            // _typeButton("M"),
            // _typeButton("P"),
            _iosPickerButton(),
          ],
        ),
      ),
    );
  }

  Widget _iosPickerButton() {
    final items = canvasSize[selectedType]!.keys.toList();
    final types = canvasSize.keys.toList();
    const double itemCount = 40;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 200,
          height: isPickerOpen ? 200 : 60, // 버튼이 위로 확장됨
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              // 상단 버튼 영역
              GestureDetector(
                onTap: () {
                  setState(() => isPickerOpen = !isPickerOpen);
                },
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$selectedType  $selectedHo호",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isPickerOpen
                            ? CupertinoIcons.chevron_down
                            : CupertinoIcons.chevron_up,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // 아래 Picker 영역
              Expanded(
                child: AnimatedOpacity(
                  opacity: isPickerOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: isPickerOpen
                      ? Row(
                          children: [
                            SizedBox(
                              height: 100,
                              width: 100, // 반드시 width를 제한해야 함
                              child: CupertinoPicker(
                                itemExtent: itemCount,
                                // scrollController: FixedExtentScrollController(
                                //   initialItem: items.indexOf(selectedHo),
                                // ),
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedType = types[index];
                                    _applyCanvasRatio();
                                  });
                                },
                                children: List.generate(types.length, (index) {
                                  final sizeType = types[index];
                                  final isSelected = sizeType == selectedType;
                                  return Center(
                                    child: Text(
                                      sizeType,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.amber
                                            : Colors.white,
                                        fontSize: isSelected ? 22 : 20,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            SizedBox(
                              height: 200,
                              width: 100, // 반드시 width를 제한해야 함
                              child: CupertinoPicker(
                                itemExtent: itemCount,
                                // scrollController: FixedExtentScrollController(
                                //   initialItem: items.indexOf(selectedHo),
                                // ),
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedHo = items[index];
                                    _applyCanvasRatio();
                                  });
                                },
                                children: List.generate(items.length, (index) {
                                  final ho = items[index];
                                  final isSelected = ho == selectedHo;
                                  return Center(
                                    child: Text(
                                      "$ho호",
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.amber
                                            : Colors.white,
                                        fontSize: isSelected ? 22 : 20,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _iosPickerButton() {
  //   return GestureDetector(
  //     onTap: () => _openCupertinoPicker(),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.white70),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Text(
  //         "$selectedHo호 선택",
  //         style: TextStyle(fontSize: 16, color: Colors.white),
  //       ),
  //     ),
  //   );
  // }

  // void _openCupertinoPicker() {
  //   final items = canvasSize[selectedType]!.keys.toList();

  //   showCupertinoModalPopup(
  //     context: context,
  //     barrierColor: Colors.transparent, // ← dim 제거 포인트
  //     builder: (_) {
  //       return Container(
  //         width: 200,
  //         height: 260,
  //         color: Colors.black.withOpacity(0.85),
  //         child: SafeArea(
  //           top: false,
  //           child: CupertinoPicker(
  //             itemExtent: 40,
  //             scrollController: FixedExtentScrollController(
  //               initialItem: items.indexOf(selectedHo),
  //             ),
  //             onSelectedItemChanged: (index) {
  //               setState(() {
  //                 selectedHo = items[index];
  //                 _applyCanvasRatio();
  //               });
  //             },
  //             children: items
  //                 .map(
  //                   (ho) => Center(
  //                     child: Text(
  //                       "$ho호",
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 20,
  //                       ),
  //                     ),
  //                   ),
  //                 )
  //                 .toList(),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // // F/M/P 버튼
  // Widget _typeButton(String t) {
  //   bool active = selectedType == t;

  //   return GestureDetector(
  //     onTap: () {
  //       setState(() {
  //         selectedType = t;
  //         selectedHo = canvasSize[t]!.keys.first;
  //         _applyCanvasRatio();
  //       });
  //     },
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
  //       decoration: BoxDecoration(
  //         color: active ? Colors.amber : Colors.grey,
  //         borderRadius: BorderRadius.circular(12),
  //         // border: Border.all(color: Colors.white),
  //       ),
  //       child: Text(
  //         t,
  //         style: TextStyle(
  //           color: active ? Colors.black : Colors.white,
  //           fontSize: 15,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // MM 규격 기반으로 실제 비율 적용
  void _applyCanvasRatio() {
    final size = canvasSize[selectedType]![selectedHo]!;
    final ratio = size.width / size.height;
    _aspectRatio = ratio;
    editorKey.currentState?.updateCropAspectRatio(ratio);
  }

  void _finishEditing() async {
    final state = editorKey.currentState;
    if (state == null) return;

    final data = state.rawImageData;

    Navigator.pop(context, data);
  }
}
