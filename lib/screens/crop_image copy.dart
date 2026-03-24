import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';

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
  String? selectedCanvas; // 0F, 1F, 0M, ...

  // --- F/M/P 캔버스 Map ---
  final Map<String, Map<String, Size>> canvasSizesByType = {
    "F": {
      "0F": const Size(180, 140),
      "1F": const Size(220, 160),
      "2F": const Size(240, 190),
      "3F": const Size(273, 220),
      "4F": const Size(333, 242),
      "6F": const Size(409, 318),
      "8F": const Size(455, 380),
      "10F": const Size(530, 455),
    },
    "M": {
      "0M": const Size(180, 120),
      "1M": const Size(220, 140),
      "2M": const Size(240, 170),
      "3M": const Size(273, 190),
      "4M": const Size(333, 220),
      "6M": const Size(409, 273),
      "8M": const Size(455, 333),
      "10M": const Size(530, 409),
    },
    "P": {
      "0P": const Size(180, 100),
      "1P": const Size(220, 120),
      "2P": const Size(240, 160),
      "3P": const Size(273, 160),
      "4P": const Size(333, 190),
      "6P": const Size(409, 242),
      "8P": const Size(455, 273),
      "10P": const Size(530, 333),
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("유화 캔버스 크롭"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _cropImage),
        ],
      ),
      body: Column(
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
                  // cornerPainter: const EditorCornerPainter(),
                  // enableGestureRotate: true,
                );
              },
            ),
          ),

          // --- Row로 Dropdown 배치 ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // --- 타입 Dropdown ---
                Expanded(
                  flex: 1,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedType,
                    hint: const Text("캔버스 타입 (F/M/P)"),
                    items: canvasSizesByType.keys.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        selectedCanvas = null; // 타입 바뀌면 호수 초기화
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
                    items: selectedType != null
                        ? canvasSizesByType[selectedType]!.keys.map((key) {
                            return DropdownMenuItem(
                              value: key,
                              child: Text(key),
                            );
                          }).toList()
                        : [],
                    onChanged: (value) {
                      if (value == null) return;
                      final size = canvasSizesByType[selectedType!]![value]!;
                      setState(() {
                        selectedCanvas = value;
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
      ),
    );
  }

  Future<void> _cropImage() async {
    final editorState = editorKey.currentState;
    if (editorState == null) return;

    final Uint8List cropped = editorState.rawImageData;
    if (!mounted) return;

    Navigator.pop(context, cropped);
  }
}
