import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_editor/controllers/crop_controller_panel.dart';
import 'package:image_editor/controllers/grid_controller_panel.dart';
import 'package:image_editor/controllers/roi_controller_panel.dart';
import 'package:image_editor/overlays/overlays.dart';
import 'package:image_editor/screens/core/canvas_core.dart';
import 'package:image_editor/screens/core/image_editor_state.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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

class EditorScreen extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const EditorScreen({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late ImageEditorState state;
  late PageController _pageController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    state = ImageEditorState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadImage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await File(
      widget.imagePaths[widget.initialIndex],
    ).readAsBytes();

    state.initWithBytes(bytes); // 👈 핵심
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              'Edit Screen (${_currentIndex + 1} / ${widget.imagePaths.length})',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => state.setAnalysisMode(!state.isAnalysisMode),
                child: Text(
                  state.isAnalysisMode ? '완료' : '편집',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              // body 안쪽은 이미 AnimatedBuilder 안이므로 중복 제거
              if (!state.isImageReady) {
                return const Center(child: CircularProgressIndicator());
              }
              // ── 크롭 탭 ───────────────────────────────────────
              if (state.isAnalysisMode && state.tabIndex == 3) {
                return Column(
                  children: [
                    Expanded(
                      child: CropTab(
                        state: state,
                        onCropDone: (bytes) {
                          state.initWithBytes(bytes);
                          state.setTabIndex(0);
                        },
                      ),
                    ),
                    _buildTabBar(),
                  ],
                );
              }

              // ── 뷰어 / 편집 탭 (ROI·Grid·Paint) ──────────────
              return Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, imageConstraints) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          state.updateLayout(
                            Size(
                              imageConstraints.maxWidth,
                              imageConstraints.maxHeight,
                            ),
                          );
                        });
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Offstage(
                              offstage: state.isAnalysisMode,
                              child: _buildPhotoGallery(),
                            ),
                            Offstage(
                              offstage: !state.isAnalysisMode,
                              child: CanvasCore(
                                state: state,
                                onInteraction: () => state.handleZoomChange(),
                              ),
                            ),
                            if (state.isAnalysisMode)
                              UnifiedOverlay(
                                state: state,
                                tabIndex: state.tabIndex,
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  // 패널
                  if (state.isAnalysisMode)
                    [
                      // 탭 0 (ROI)
                      RoiControlPanel(
                        roiSize: state.roiSize,
                        isMinimumCount: state.isMinimumCount,
                        onSizeChanged: (v) => state.setRoiSize(v),
                        onMinimumToggle: (v) => state.setMinimumMode(v),
                        onAnalyze: () => state.updateRoiAnalysis(),
                      ),
                      // 탭 1 (Grid)
                      GridControlPanel(
                        divisions: state.gridDivisions,
                        isWidthBase: state.gridWidthBase,
                        showGrid: state.showGrid,
                        lineColor: state.gridColor,
                        onDivisionsChanged: (v) => state.setGridDivisions(v),
                        onWidthBaseChanged: (v) => state.setGridWidthBase(v),
                        onShowGridChanged: (v) => state.setShowGrid(v),
                        onColorChanged: (c) => state.setGridColor(c),
                      ),
                      // 탭 2 (Paint) — 썸네일 + 색상 결과 + ROI 컨트롤
                      _PaintPanel(state: state),
                    ][state.tabIndex.clamp(0, 2)],

                  if (state.isAnalysisMode) _buildTabBar(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      color: Colors.black.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem(0, Icons.filter_center_focus, "ROI"),
          _buildTabItem(1, Icons.grid_on, "Grid"),
          _buildTabItem(2, Icons.palette, "색상 분석"),
          _buildTabItem(3, Icons.crop, "크롭"),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = state.tabIndex == index;
    return GestureDetector(
      onTap: () => state.setTabIndex(index), // setState 없이 state만 업데이트
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.amber : Colors.grey),
          Text(
            label,
            style: TextStyle(color: isSelected ? Colors.amber : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return PhotoViewGallery.builder(
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      itemCount: widget.imagePaths.length,
      pageController: _pageController,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      builder: (context, index) {
        final imagePath = widget.imagePaths[index];
        return PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(imagePath)),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
        );
      },
      scrollPhysics: const BouncingScrollPhysics(),
    );
  }
}

// ── Paint 탭 패널 ────────────────────────────────────────────────────────────
class _PaintPanel extends StatelessWidget {
  final ImageEditorState state;
  const _PaintPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 썸네일 ──────────────────────────────────────
                Column(
                  children: [
                    const Text(
                      'ROI 영역',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.black,
                      ),
                      child: state.croppedPreview != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.memory(
                                state.croppedPreview!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              color: Colors.white24,
                              size: 28,
                            ),
                    ),
                    const SizedBox(height: 6),
                    // 추출 색상 칩
                    Container(
                      width: 72,
                      height: 24,
                      decoration: BoxDecoration(
                        color: state.extractedColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '추출 색상',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // ── 분석 결과 ────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.recommendedPaints.isNotEmpty) ...[
                        const Text(
                          '추천 유화 색',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...state.recommendedPaints
                            .take(3)
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        const SizedBox(height: 10),
                      ],
                      if (state.bestMix != null) ...[
                        const Text(
                          '혼합 비율',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        ...List.generate(state.bestMix!.paints.length, (i) {
                          final w = state.bestMix!.weights[i];
                          if (w <= 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    state.bestMix!.paints[i].name,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(w * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── ROI 크기 + 분석 버튼 ──────────────────────────────
            Row(
              children: [
                const Text(
                  '크기',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.cyanAccent,
                      thumbColor: Colors.white,
                      inactiveTrackColor: Colors.white12,
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: state.roiSize,
                      min: 20,
                      max: 120,
                      onChanged: (v) => state.setRoiSize(v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: () => state.updateRoiAnalysis(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('분석', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
