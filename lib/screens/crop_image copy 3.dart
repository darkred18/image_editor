import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:image_editor/models/size_model.dart';

class CanvasSize {
  final double width;
  final double height;
  final double ratio;

  CanvasSize({required this.width, required this.height, required this.ratio});

  factory CanvasSize.fromJson(Map<String, dynamic> json) {
    return CanvasSize(
      width: json['width'],
      height: json['height'],
      ratio: json['ratio'],
    );
  }
}

class CanvasCropPage extends StatefulWidget {
  final Uint8List imageBytes;
  const CanvasCropPage({super.key, required this.imageBytes});

  @override
  State<CanvasCropPage> createState() => _CanvasCropPageState();
}

class _CanvasCropPageState extends State<CanvasCropPage> {
  final editorKey = GlobalKey<ExtendedImageEditorState>();

  bool cropMode = false;
  double? _aspectRatio;

  // 현재 선택값
  // String selectedType = "F";
  // String selectedHo = "1";
  // int selectedHo = 6;

  final int pickerCount = 2;

  final List<int> _selectedIndexes = [0, 0];
  List<FixedExtentScrollController> _controllers = [];

  bool _isPickerOpen = false;
  double pickerHeight = 60; // 기본 버튼 높이

  late dynamic _canvasSize;
  List<String>? _types;
  List<String>? _items;

  double itemCount = 40;

  @override
  void initState() {
    super.initState();
    loadSizes();

    // 피커 초기값 설정
    // 컨트롤러 생성 후 배열에 저장
    _controllers = List.generate(
      pickerCount,
      (i) => FixedExtentScrollController(initialItem: _selectedIndexes[i]),
    );
    // String selectedType = "F";
    // // pickerCount 횟수만큼 반복
    // for (int i = 0; i < pickerCount; i++) {
    //   // 각 인덱스(i)에 해당하는 selectedIndexes 값을 initialItem으로 설정하여 컨트롤러 생성
    //   if(i==1){
    //     selectedType = items[selectedIndexes[i]];
    //   }
    //   _controllers[i] = FixedExtentScrollController(
    //     initialItem: selectedType,
    //   );
    //   // 임시 리스트에 추가
    //   tempControllers.add(controller);
    // }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void loadSizes() async {
    // <String, Map<String, CanvasSize>>
    _canvasSize = await loadCanvasSizes();

    _types = _canvasSize.keys.toList();
    _items = _canvasSize.values.toList()[0].keys.toList();

    print(_canvasSize["F"]?["1"]?.width); // 22.7
    print(_canvasSize["F"]?["1"]?.height); // 15.8
    print(_canvasSize["F"]?["1"]?.ratio); // 1.4367
  }

  Future<Map<String, Map<String, CanvasSize>>> loadCanvasSizes() async {
    final jsonString = await rootBundle.loadString('assets/canvas_size.json');
    final Map<String, dynamic> raw = jsonDecode(jsonString);

    final result = <String, Map<String, CanvasSize>>{};

    raw.forEach((category, items) {
      final innerMap = <String, CanvasSize>{};

      (items as Map<String, dynamic>).forEach((key, value) {
        innerMap[key] = CanvasSize.fromJson(value);
      });

      result[category] = innerMap;
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("캔버스 비율 크롭"),
        actions: [
          TextButton(
            onPressed: _finishEditing,
            child: const Text(
              "완료",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 이미지
          Expanded(
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
          _iosPickerButton(),
          const SizedBox(height: 20),
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

  // Widget _buildPickerContainer() {
  //   return AnimatedOpacity(
  //     opacity: cropMode ? 1 : 0,
  //     duration: const Duration(milliseconds: 200),
  //     child: Container(
  //       padding: const EdgeInsets.all(14),
  //       margin: const EdgeInsets.symmetric(horizontal: 16),
  //       // decoration: BoxDecoration(
  //       //   color: Colors.black.withAlpha(140),
  //       //   borderRadius: BorderRadius.circular(20),
  //       // ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceAround,
  //         children: [
  //           // _typeButton("F"),
  //           // _typeButton("M"),
  //           // _typeButton("P"),
  //           _buildPickerContainer(),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPickerLabel(String text, bool isSelected, {bool addHo = false}) {
    return Center(
      child: Text(
        addHo ? "$text호" : text,
        style: TextStyle(
          color: isSelected ? Colors.amber : Colors.white,
          fontSize: isSelected ? 22 : 20,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCupertinoPicker({
    required List<String> data,
    required double width,
    required double height,
    required double itemExtent,
    required String selectedValue,
    bool addHo = false,
    required ValueChanged<String> onSelected,
    required FixedExtentScrollController scrollController,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: CupertinoPicker(
        itemExtent: itemExtent,
        scrollController: scrollController,
        onSelectedItemChanged: (index) {
          onSelected(data[index]);
          debugPrint("onSelectedItemChanged : $index");
        },
        children: List.generate(data.length, (index) {
          debugPrint("Picker building index: $index");
          final value = data[index];
          final isSelected = value == selectedValue;
          return _buildPickerLabel(value, isSelected, addHo: addHo);
        }),
      ),
    );
  }

  Widget _buildPickerContainer() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ColoredBox(
        color: Colors.amber[50]!,
        child: SizedBox(
          height: _isPickerOpen ? 200.0 : 0.0,
          child: Row(
            children: [
              // 🌟 분리된 위젯을 사용하여 첫 번째 피커 생성
              SinglePicker(
                items: _types!,
                controller: _controllers[0],
                addHo: false,
                onSelectedItemChanged: (int selectedItemIndex) {
                  setState(() {
                    _selectedIndexes[0] = selectedItemIndex;
                  });
                },
              ),

              // 🌟 분리된 위젯을 사용하여 두 번째 피커 생성
              SinglePicker(
                items: _items!,
                controller: _controllers[1],
                addHo: true,
                onSelectedItemChanged: (int selectedItemIndex) {
                  setState(() {
                    _selectedIndexes[1] = selectedItemIndex;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iosPickerButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 200,
          height: _isPickerOpen ? 200 : 60, // 버튼이 위로 확장됨
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(200),
            borderRadius: BorderRadius.circular(14),
          ),

          child: Column(
            children: [
              // 상단 버튼 영역
              GestureDetector(
                onTap: () {
                  // setState(() => isPickerOpen = !isPickerOpen);
                  setState(() {
                    _isPickerOpen = !_isPickerOpen;
                  });
                },
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${_types?[_selectedIndexes[0]]}  ${_items?[_selectedIndexes[1]]}호",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isPickerOpen
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
                  opacity: _isPickerOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _isPickerOpen
                      ? Row(
                          children: [
                            // // 유형(타입) Picker
                            // _buildCupertinoPicker(
                            //   data: types,
                            //   width: 100,
                            //   height: 200,
                            //   itemExtent: itemCount,
                            //   selectedValue: selectedType,
                            //   scrollController: _controllers[0],
                            //   addHo: false,
                            //   onSelected: (value) {
                            //     setState(() {
                            //       selectedType = value;
                            //       selectedIndexes[0] = types.indexOf(value);
                            //       _applyCanvasRatio();
                            //     });
                            //   },
                            // ),
                            SinglePicker(
                              items: _types!,
                              controller: _controllers[0],
                              addHo: false,
                              onSelectedItemChanged: (int selectedItemIndex) {
                                setState(() {
                                  _selectedIndexes[0] = selectedItemIndex;
                                  _applyCanvasRatio();
                                });
                              },
                            ),
                            SinglePicker(
                              items: _items!,
                              controller: _controllers[1],
                              addHo: true,
                              onSelectedItemChanged: (int selectedItemIndex) {
                                setState(() {
                                  _selectedIndexes[1] = selectedItemIndex;
                                  _applyCanvasRatio();
                                });
                              },
                            ),

                            // 호 Picker
                            // _buildCupertinoPicker(
                            //   data: items,
                            //   width: 100,
                            //   height: 200,
                            //   itemExtent: itemCount,
                            //   selectedValue: selectedHo,
                            //   scrollController: _controllers[1],
                            //   addHo: true,
                            //   onSelected: (value) {
                            //     setState(() {
                            //       selectedHo = value;
                            //       selectedIndexes[1] = types.indexOf(value);
                            //       _applyCanvasRatio();
                            //     });
                            //   },
                            // ),
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

  // MM 규격 기반으로 실제 비율 적용
  void _applyCanvasRatio() {
    // final String firstKey = _types![_selectedIndexes[0]];
    // print('--- 디버깅 ---');
    // print('찾는 첫 번째 키: $firstKey');
    // print('첫 번째 키로 검색된 값 (Map): ${_canvasSize[firstKey]}'); // 널인지 확인
    // // ...
    // final String secondKey = _items![_selectedIndexes[1]];
    // print('찾는 두 번째 키: $secondKey');

    // final innerMap = _canvasSize[firstKey];

    // if (innerMap != null) {
    //   print('두 번째 키로 검색된 최종 값: ${innerMap[secondKey]}'); // 널인지 확인
    // }
    // ...
    // final size =
    //     _canvasSize[_types![_selectedIndexes[0]]]![_selectedIndexes[1]]!;
    final size =
        _canvasSize[_types![_selectedIndexes[0]]]?[_items![_selectedIndexes[1]]];

    final ratio = size!.width / size.height;
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

// 1. 재사용 가능한 단일 피커 위젯 (StatelessWidget)
class SinglePicker extends StatelessWidget {
  final List<String> items;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onSelectedItemChanged;
  final bool addHo;

  const SinglePicker({
    super.key,
    required this.items,
    required this.controller,
    required this.onSelectedItemChanged,
    required this.addHo,
  });

  Widget _buildPickerLabel(String text, bool isSelected, {bool addHo = false}) {
    return Center(
      child: Text(
        addHo ? "$text호" : text,
        style: TextStyle(
          color: isSelected ? Colors.amber : Colors.white,
          fontSize: isSelected ? 22 : 20,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 40.0,
        scrollController: controller,
        onSelectedItemChanged: onSelectedItemChanged,
        // children: items.map((String fruit) {
        //   return Center(
        //     child: Text(fruit, style: const TextStyle(fontSize: 20)),
        //   );
        // }).toList(),
        children: List.generate(items.length, (index) {
          final value = items[index];
          late dynamic isSelected = value == items[index];

          return _buildPickerLabel(value, isSelected, addHo: addHo);
        }),
      ),
    );
  }
}
// children: List.generate(data.length, (index) {
//           debugPrint("Picker building index: $index");
//           final value = data[index];
//           final isSelected = value == selectedValue;
//           return _buildPickerLabel(value, isSelected, addHo: addHo);
//         }),