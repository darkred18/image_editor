import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';
import 'package:image_editor/screens/crop_image.dart';

/// 크롭 탭 전체 레이아웃
/// - 상단: ExtendedImage 에디터 (이미지 + 크롭 UI)
/// - 하단: 비율 선택 패널
/// canvasSize는 assets/canvas_size.json에서 내부적으로 로드
class CropTab extends StatefulWidget {
  final ImageEditorState state;
  final void Function(Uint8List croppedBytes) onCropDone;

  const CropTab({super.key, required this.state, required this.onCropDone});

  @override
  State<CropTab> createState() => _CropTabState();
}

class _CropTabState extends State<CropTab> {
  final _editorKey = GlobalKey<ExtendedImageEditorState>();

  double? _aspectRatio;
  bool _sizeSwapped = false;

  Map<String, Map<String, CanvasSizeModel>> _canvasSize = {};
  List<String> _types = ['FREE'];
  List<String> _items = [];
  int _typeIndex = 0;
  int _itemIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSizes();
  }

  Future<void> _loadSizes() async {
    final jsonStr = await rootBundle.loadString('assets/canvas_size.json');
    final Map<String, dynamic> raw = jsonDecode(jsonStr);

    final parsed = raw.map(
      (type, hoMap) => MapEntry(
        type,
        (hoMap as Map<String, dynamic>).map(
          (ho, sizeMap) => MapEntry(
            ho,
            CanvasSizeModel.fromJson(sizeMap as Map<String, dynamic>),
          ),
        ),
      ),
    );

    setState(() {
      _canvasSize = parsed;
      _types = ['FREE', ...parsed.keys];
      _items = parsed.values.first.keys.toList();
      _isLoading = false;
    });
  }

  // ── 비율 적용 ─────────────────────────────────────────────────
  void _applyRatio() {
    if (_typeIndex == 0) {
      _aspectRatio = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editorKey.currentState?.updateCropAspectRatio(null);
      });
      return;
    }

    final categoryKey = _types[_typeIndex];
    final itemKey = _items[_itemIndex];
    final size = _canvasSize[categoryKey]?[itemKey];
    if (size == null) return;

    // 스왑 여부에 따라 비율 계산
    // 기본: width/height (가로가 긴 비율)
    // 스왑: height/width (세로가 긴 비율)
    final double ratio = _sizeSwapped
        ? size.height / size.width
        : size.width / size.height;

    // _aspectRatio는 ExtendedImage 재생성 없이 updateCropAspectRatio로만 전달
    // setState 없이 직접 업데이트 → 위젯 재생성 방지
    _aspectRatio = ratio;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editorKey.currentState?.updateCropAspectRatio(ratio);
    });
  }

  // ── 크롭 완료 ─────────────────────────────────────────────────
  Future<void> _finishCrop() async {
    final editorState = _editorKey.currentState;
    if (editorState == null) return;

    final cropRect = editorState.getCropRect();
    if (cropRect == null) return;

    // ExtendedImage의 cropImageData로 실제 크롭 수행
    final result = await cropImageDataWithNativeLibrary(state: editorState);
    if (result == null) return;

    widget.onCropDone(result);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    return Column(
      children: [
        // ── 이미지 에디터 영역 ──────────────────────────────────
        Expanded(
          child: ExtendedImage.memory(
            widget.state.imageBytes,
            mode: ExtendedImageMode.editor,
            extendedImageEditorKey: _editorKey,
            fit: BoxFit.contain,
            initGestureConfigHandler: (_) => GestureConfig(
              minScale: 0.8,
              maxScale: 8.0,
              initialScale: 1.0,
              inPageView: false,
            ),
            initEditorConfigHandler: (_) => EditorConfig(
              cropAspectRatio: _aspectRatio,
              maxScale: 8.0,
              lineColor: Colors.cyanAccent.withOpacity(0.8),
              lineHeight: 1.0,
              cornerColor: Colors.cyanAccent,
            ),
          ),
        ),

        // ── 하단 컨트롤 패널 ────────────────────────────────────
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
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
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ── 타입 선택 (F, P, M ...) ──────────────────
                _SectionLabel(label: '캔버스 타입'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _types.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _ChipButton(
                      label: _types[i],
                      selected: _typeIndex == i,
                      onTap: () {
                        setState(() {
                          _typeIndex = i;
                          _itemIndex = 0;
                          // 타입 바뀌면 items 갱신
                          if (i > 0) {
                            final key = _types[i];
                            _items = _canvasSize[key]?.keys.toList() ?? [];
                          }
                        });
                        _applyRatio();
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── 호수 선택 (FREE가 아닐 때만) ─────────────
                if (_typeIndex > 0) ...[
                  _SectionLabel(label: '호수'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _ChipButton(
                        label: _items[i],
                        selected: _itemIndex == i,
                        onTap: () {
                          setState(() => _itemIndex = i);
                          _applyRatio();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 가로/세로 스왑 ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '가로 ↔ 세로',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Switch(
                        value: _sizeSwapped,
                        activeColor: Colors.cyanAccent,
                        onChanged: (v) {
                          setState(() => _sizeSwapped = v);
                          _applyRatio();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // ── 크롭 완료 버튼 ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _finishCrop,
                    icon: const Icon(Icons.crop, size: 18),
                    label: const Text('크롭 완료'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<dynamic> cropImageDataWithNativeLibrary({
    required ExtendedImageEditorState state,
  }) async {}
}

// ── 헬퍼 위젯들 ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.cyanAccent : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.cyanAccent : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
