import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/screens/crop_image.dart';
import 'package:image_editor/widgets/double_picker.dart';
import 'package:image_editor/widgets/swap_button.dart';

// class CanvasSizeModel {
//   final double width;
//   final double height;
//   final double ratio;

//   CanvasSizeModel({
//     required this.width,
//     required this.height,
//     required this.ratio,
//   });

//   factory CanvasSizeModel.fromJson(Map<String, dynamic> json) {
//     return CanvasSizeModel(
//       width: json['width'],
//       height: json['height'],
//       ratio: json['ratio'],
//     );
//   }
// }

class CanvasCropExtendPage extends StatefulWidget {
  final Uint8List imageBytes;
  final Map<String, Map<String, CanvasSizeModel>> canvasSize;
  const CanvasCropExtendPage({
    super.key,
    required this.imageBytes,
    required this.canvasSize,
  });

  @override
  State<CanvasCropExtendPage> createState() => _CanvasCropExtendPageState();
}

class _CanvasCropExtendPageState extends State<CanvasCropExtendPage> {
  final editorKey = GlobalKey<ExtendedImageEditorState>();

  late final DoublePicker _picker = DoublePicker(
    items: [[]],
    selectedItemChanged: _applyCanvasRatio,
    selectedIndexes: _selectedIndexes,
  );

  // bool cropMode = false;
  double? _aspectRatio;

  // 현재 선택값
  // String selectedType = "F";
  // String selectedHo = "1";
  // int selectedHo = 6;

  // final int pickerCount = 2;

  // late dynamic _canvasSize;
  late List<String> _types;
  late List<String> _items;

  final List<int> _selectedIndexes = [0, 0];
  bool _sizeSwapped = false;

  final MaterialColor testColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    loadSizes();
  }

  void loadSizes() {
    _types = widget.canvasSize.keys.toList();
    _types.insert(0, 'FREE');
    _items = widget.canvasSize.values.toList()[0].keys.toList();
    // _items = _items!.map((e) => '$e호').toList();

    // print(widget.canvasSize["F"]?["1"]?.width); // 22.7
    // print(widget.canvasSize["F"]?["1"]?.height); // 15.8
    // print(widget.canvasSize["F"]?["1"]?.ratio); // 1.4367

    setState(() {
      _picker.items = [_types, _items];
    });
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
              style: TextStyle(color: Colors.black, fontSize: 16),
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
                  // 격자/경계선 색
                  lineColor: testColor.shade500,
                  // 선 두께
                  lineHeight: 1.0,
                  // 모서리 색
                  cornerColor: testColor,
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _picker,
              SwapRadioButtons(onChanged: _test),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // Future<void> _cropAndSaveImage() async {
  //   final ExtendedImageEditorState? editorState = editorKey.currentState;

  //   if (editorState == null || editorState.getCropRect() == null) {
  //     print("편집기 상태가 유효하지 않거나 영역이 지정되지 않았습니다.");
  //     return;
  //   }

  //   // 1. 사용자가 핸들로 조작한 영역(Rect) 가져오기
  //   final Rect cropRect = editorState.getCropRect()!;

  //   // 2. 현재 편집 중인 원본 이미지 데이터
  //   final Uint8List rawData = editorState.rawImageData;

  //   try {
  //     // 🌟 extended_image에서 제공하는 내장 크롭 함수 사용
  //     final Uint8List? croppedData = await cropImageDataWithDartUi(
  //       settings: EditorCropLayerSettings(
  //         cropRect: cropRect,
  //       ),
  //       image: rawData,
  //     );

  //     if (croppedData != null) {
  //       // 3. 결과물(croppedData)을 파일로 저장하거나 서버로 전송
  //       print("자르기 완료! 데이터 크기: ${croppedData.length}");

  //       // 예: 서버 전송용 변수에 담기 또는 화면에 보여주기
  //       // setState(() { _resultImage = croppedData; });
  //     }
  //   } catch (e) {
  //     print("이미지 자르기 중 오류 발생: $e");
  //   }
  // }

  void _test(bool swaped) {
    print('test object.  swaped: $swaped');
    _sizeSwapped = swaped;
    _applyCanvasRatio();
  }

  void _applyCanvasRatio() {
    print('_applyCanvasRatio------------------------ ');

    // 1. 인덱스 0 (자유 비율) 처리
    final int firstIndex = _picker.selectedIndexes[0];
    if (firstIndex == 0) {
      _aspectRatio = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        editorKey.currentState?.updateCropAspectRatio(_aspectRatio);
      });

      return;
    }
    final int secondIndex = _picker.selectedIndexes[1];
    // print('firstIndex---- $firstIndex');
    // print('secondIndex---- $secondIndex');

    // 2. 키 값 추출 시 널 안전성 강화
    // _types와 _items는 late final로 선언되었고, initState에서 초기화되었다고 가정합니다.
    final String categoryKey = _types[firstIndex];

    final String itemKey = _items[secondIndex];

    // 3. 맵 접근 시 조건부 접근 연산자만 사용하여 안전성 확보
    final size = widget.canvasSize[categoryKey]?[itemKey];

    // 4. 널 검사 및 대체 로직 (가장 중요!)
    if (size == null) {
      // 데이터가 Map에 없는 경우 (예외 상황)
      // ⚠️ 경고: 기본 비율(예: 1.0)을 적용하거나 로깅해야 합니다.
      print('오류: $categoryKey 또는 $itemKey에 해당하는 CanvasSize 데이터를 찾을 수 없습니다.');
      _aspectRatio = 1.0; // 안전한 기본 비율 설정
      editorKey.currentState?.updateCropAspectRatio(1.0);
      return; // 함수 종료
    }
    double ratio = size.ratio;
    double width = size.width;
    double height = size.height;
    if (_sizeSwapped) {
      (width, height) = (size.height, size.width);
      ratio = width / height;
    }

    // 6. 상태 및 편집기에 비율 적용
    _aspectRatio = ratio;
    // editorKey.currentState가 null이 아닐 때만 실행
    editorKey.currentState?.updateCropAspectRatio(ratio);
  }
  // void _applyCanvasRatio() {
  //   final size =
  //       widget.canvasSize[_types![_picker.selectedIndexes[0]]]?[_items![_picker
  //           .selectedIndexes[1]]];

  //   final ratio = size!.width / size.height;
  //   _aspectRatio = ratio;
  //   editorKey.currentState?.updateCropAspectRatio(ratio);
  // }

  void _finishEditing() async {
    // editorKey를 통해 현재 상태 가져오기
    final ExtendedImageEditorState? editorState = editorKey.currentState;

    if (editorState == null) return;
    // 2. 현재 사용자가 지정한 크롭 영역(Rect) 가져오기
    final Rect? cropRect = editorState.getCropRect();
    if (cropRect == null) return;

    // 3. 원본 이미지 데이터
    final Uint8List rawData = editorState.rawImageData;

    // try {
    //   // 🌟 여기서 호출하는 겁니다!
    //   // 클래스 메서드가 아니므로 그냥 이름만 호출하거나
    //   // 에러가 지속되면 패키지명을 확인해야 합니다.
    //   // final Uint8List? croppedData = await cropImageDataWithDartUi(
    //   //   settings: EditorCropLayerSettings(cropRect: cropRect),
    //   //   image: rawData,
    //   // );

    //   // if (croppedData != null) {
    //   //   print("자르기 성공! ${croppedData.length} 바이트");
    //     // 여기서 croppedData를 활용하세요 (화면에 보여주거나 서버 전송)
    //   }
    // } catch (e) {
    //   print("자르기 중 오류 발생: $e");
    //   // 만약 여전히 'undefined'가 뜬다면, 패키지 버전이나
    //   // 프로젝트에 해당 유틸리티 파일이 포함되어 있는지 확인해야 합니다.
    // }
  }
}
