import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/services.dart';
// import 'package:image_editor/models/dimension_model.dart'; // 경로는 프로젝트에 맞게 수정

// 가정: dimension_model.dart 파일이 lib/models/dimension_model.dart에 있다고 가정합니다.
import 'package:image_editor/models/dimension_model.dart';

class CanvasCropPage extends StatefulWidget {
  final Uint8List imageBytes;
  const CanvasCropPage({super.key, required this.imageBytes});

  @override
  State<CanvasCropPage> createState() => _CanvasCropPageState();
}

class _CanvasCropPageState extends State<CanvasCropPage> {
  final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey();

  double? _aspectRatio;

  String? selectedType; // F / M / P
  String? selectedCanvas; // 0, 1, 2, ... (호수)

  // JSON 파일을 로드하고 파싱하는 함수를 호출하여 Future 객체 생성
  // 데이터 타입은 Map<규격, Map<호수, DimensionModel>> 입니다.
  late final Future<Map<String, Map<String, DimensionModel>>> _futureData =
      loadAndParseSizes();

  @override
  void initState() {
    super.initState();
    // initState에서 불필요한 _loadData() 호출 제거: FutureBuilder가 처리합니다.
  }

  // --- JSON 로딩 및 파싱 함수 (통합 및 수정) ---
  Future<Map<String, Map<String, DimensionModel>>> loadAndParseSizes() async {
    try {
      // JSON 파일 경로를 'assets/painting_sizes.json'로 통일
      final String response = await rootBundle.loadString(
        'assets/canvas_size.json',
      );
      final Map<String, dynamic> rawData = jsonDecode(response);

      final Map<String, Map<String, DimensionModel>> parsedData = {};

      rawData.forEach((key, value) {
        // 'F', 'P', 'M' (key)
        final Map<String, dynamic> innerMap = value as Map<String, dynamic>;
        final Map<String, DimensionModel> dimensionsByHo = {};

        innerMap.forEach((ho, dimensionData) {
          // '1', '2', '3' (ho)
          dimensionsByHo[ho] = DimensionModel.fromJson(
            dimensionData as Map<String, dynamic>,
          );
        });

        parsedData[key] = dimensionsByHo;
      });

      return parsedData;
    } catch (e) {
      // 로딩 또는 파싱 실패 시 에러 던지기
      throw Exception("JSON 데이터 로딩 및 파싱 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("유화 캔버스 크롭"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _cropImage),
        ],
      ),
      body: FutureBuilder<Map<String, Map<String, DimensionModel>>>(
        future: _futureData,
        builder: (context, asyncSnapshot) {
          // [1] 에러 처리
          if (asyncSnapshot.hasError) {
            return Center(child: Text('데이터 로드 에러: ${asyncSnapshot.error}'));
          }

          // [2] 로딩 중
          if (asyncSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // [3] 로딩 완료 (asyncSnapshot.data에 실제 데이터가 담겨 있습니다.)
          final Map<String, Map<String, DimensionModel>> allSizes =
              asyncSnapshot.data!;

          // selectedType에 따른 호수 맵 (Map<String, DimensionModel>)
          final Map<String, DimensionModel>? selectedSizeMap =
              selectedType != null ? allSizes[selectedType!] : null;

          return Column(
            children: [
              Expanded(
                child: ExtendedImage.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                  extendedImageEditorKey: editorKey,
                  mode: ExtendedImageMode.editor,
                  initEditorConfigHandler: (_) {
                    return EditorConfig(
                      cropAspectRatio: _aspectRatio,
                      maxScale: 8.0,
                      hitTestSize: 30.0,
                    );
                  },
                ),
              ),

              // --- Row로 Dropdown 배치 ---
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // --- 타입 Dropdown (F/M/P) ---
                    Expanded(
                      flex: 1,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedType,
                        hint: const Text("캔버스 타입 (F/M/P)"),
                        // [수정] _futureData.keys 대신 allSizes (snapshot.data)의 keys 사용
                        items: allSizes.keys.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value;
                            selectedCanvas = null; // 타입 바뀌면 호수 초기화
                            _aspectRatio = null; // 비율 초기화
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // --- 호수 Dropdown ---
                    Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCanvas,
                        hint: const Text("호수 선택"),
                        // [수정] selectedSizeMap의 keys 사용 및 널 체크
                        items: selectedSizeMap != null
                            ? selectedSizeMap.keys.map((key) {
                                return DropdownMenuItem(
                                  value: key,
                                  child: Text(key),
                                );
                              }).toList()
                            : [],
                        onChanged: (value) {
                          if (value == null || selectedSizeMap == null) return;

                          // [수정] null 체크 및 안전한 접근
                          final DimensionModel? size = selectedSizeMap[value];

                          if (size == null) return;

                          setState(() {
                            selectedCanvas = value;
                            // 비율 계산 및 적용
                            _aspectRatio = size.width / size.height;
                            editorKey.currentState?.updateCropAspectRatio(
                              _aspectRatio,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 나머지 함수는 유지
  Future<void> _cropImage() async {
    final editorState = editorKey.currentState;
    if (editorState == null) return;

    final Uint8List cropped = editorState.rawImageData;
    if (!mounted) return;

    Navigator.pop(context, cropped);
  }
}
