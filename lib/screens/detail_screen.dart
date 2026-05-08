import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/screens/crop_image.dart'; // CanvasCropPage 경로// ImageEditorPage 경로
import 'package:image_editor/screens/crop_image_extend.dart';
import 'package:image_editor/screens/opencv/image_simplification_screen.dart';
import 'package:image_editor/screens/opencv/roi_picker_screen.dart';

// RemotePage 경로
import 'package:image_editor/widgets/drag_bottom_slide.dart';

import 'package:image_editor/widgets/guide_grid.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'opencv/perspective_crop_screen.dart';

// 임시 정의: 실제 프로젝트 파일에 맞춰 이 부분을 수정해야 합니다.
class ImageInfoData {
  final String fileName;
  final String fileSize;
  final int width;
  final int height;
  ImageInfoData(this.fileName, this.fileSize, this.width, this.height);
}

// 임시 함수: 파일을 읽어 정보를 가져온다고 가정
Future<ImageInfoData> getImageInfo(String path) async {
  await Future.delayed(const Duration(milliseconds: 100));
  final file = File(path);
  // 실제 파일 정보 로딩 로직 (크기, 해상도 등)이 여기에 들어갑니다.
  return ImageInfoData(
    file.path.split('/').last,
    '${(await file.length()) / 1024} KB',
    1920, // 임시값
    1080, // 임시값
  );
}

class DetailScreen extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const DetailScreen({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  int _activeMode = 0; // 0: 뷰어, 1: 그리드, 2: ROI 분석 등

  bool showInfo = false;
  ImageInfoData? info;

  late dynamic _canvasSize;

  @override
  void initState() {
    super.initState();
    _initializeData();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _initializeData() async {
    _canvasSize = await loadCanvasSizes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Map<String, Map<String, CanvasSizeModel>>> loadCanvasSizes() async {
    final jsonString = await rootBundle.loadString('assets/canvas_size.json');
    final Map<String, dynamic> raw = jsonDecode(jsonString);

    final result = <String, Map<String, CanvasSizeModel>>{};

    raw.forEach((category, items) {
      final innerMap = <String, CanvasSizeModel>{};

      (items as Map<String, dynamic>).forEach((key, value) {
        innerMap[key] = CanvasSizeModel.fromJson(value);
      });

      result[category] = innerMap;
    });
    return result;
  }

  // --- 유틸리티 함수: 현재 이미지 바이트 로딩 ---
  Future<Uint8List> _getCurrentImageBytes() async {
    final imagePath = widget.imagePaths[_currentIndex];
    return await File(imagePath).readAsBytes();
  }

  // --- 캔버스 편집 페이지 열기 및 결과 처리 ---
  void _openCanvasCropPage() async {
    // 1. 현재 선택된 이미지의 바이트 데이터를 로드
    final Uint8List originalBytes = await _getCurrentImageBytes();
    if (!context.mounted) return;

    // 2. CanvasCropPage를 덮어 씌우며(push) 열고, 결과(croppedImageBytes)를 기다립니다.
    final croppedImageBytes = await Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => CanvasCropExtendPage(
          imageBytes: originalBytes,
          canvasSize: _canvasSize,
          // testImage: Image.asset(widget.imagePaths[_currentIndex]),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // 3. CanvasCropPage에서 Navigator.pop으로 돌아왔을 때 결과 처리
    if (croppedImageBytes != null && croppedImageBytes is Uint8List) {
      print('✅ 이미지 편집 완료. 바이트 데이터 수신.');
    } else {
      print('❌ 편집이 취소되었습니다.');
    }
  }

  // --- ImageEditorPage 열기 ---
  void _openGridEditorPage() async {
    final Uint8List bytes = await _getCurrentImageBytes();

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => GridEditorPage(imageBytes: bytes),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // --- 정보 패널 토글 ---
  void _toggleInfoPanel() async {
    final data = await getImageInfo(widget.imagePaths[_currentIndex]);
    setState(() {
      info = data;
      showInfo = !showInfo;
    });
  }

  double temp = 0;
  Widget _buildIOSPanel(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              color: Colors.white.withOpacity(0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const Text(
                  "Adjust Volume",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // 예시 슬라이더
                Slider(
                  min: 0,
                  max: 100,
                  value: temp,
                  onChanged: (v) {
                    print(v);
                    setState(() {
                      temp = v;
                    });
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool panelVisible = false;
  bool panelGrid = false;

  List<Uint8List> _getTemp(List<String> imagePaths) {
    List<Uint8List> images = [];
    for (var i = 0; i < imagePaths.length; i++) {
      final img = cv.imread(imagePaths[i], flags: cv.IMREAD_COLOR);
      final gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);
      print("${img.rows}, ${img.cols}");
      final (success, bytes) = cv.imencode(".jpg", gray);
      images.add(bytes);
    }
    // cv.imwrite("test_cvtcolor.png", gray);

    // 1. Mat을 jpg 포맷으로 인코딩하여 바이트 데이터로 변환
    return images;

    // return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight = 260.0;
    final List<Uint8List> processedImages = _getTemp(widget.imagePaths);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Detail Screen (${_currentIndex + 1} / ${widget.imagePaths.length})',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // 1층: 스와이프 가능한 이미지 레이어
          PhotoViewGallery.builder(
            backgroundDecoration: const BoxDecoration(
              color: Colors.black, // 원하는 색상으로 변경 (예: Colors.grey[900])
            ),
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

              //----------------------------------
              // open cv 를 이용한 이미지 변환
              // imageProvider: MemoryImage(
              //   processedImages[index],
              // ), // 메모리 이미지 사용
              // initialScale: PhotoViewComputedScale.contained,
              // minScale: PhotoViewComputedScale.contained * 0.8,
              // maxScale: PhotoViewComputedScale.covered * 2,
              // heroAttributes: PhotoViewHeroAttributes(tag: "image_$index"),
              // );
            },
            scrollPhysics: const BouncingScrollPhysics(),
          ),

          // ★ 정보 패널
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: showInfo ? 0 : -180, // ← 숨겨졌다가 올라옴
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: info == null
                  ? const Center(child: CircularProgressIndicator()) // 정보 로딩 중
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name: ${info!.fileName}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Size: ${info!.fileSize}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Resolution: ${info!.width} x ${info!.height}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
          // // 📌 iOS 스타일 슬라이드 패널
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: panelVisible ? 0 : -panelHeight,
            child: _buildIOSPanel(panelHeight),
          ),
          if (panelGrid)
            IOSDraggablePanel(
              // scrollController: controller,
              onClose: () => setState(() => panelVisible = false),
            ),

          if (panelVisible)
            IOSDraggablePanel(
              // scrollController: controller,
              onClose: () => setState(() => panelVisible = false),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 50,
        color: Colors.black54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 캔버스 크롭: _openCanvasCropPage 호출
            IconButton(
              icon: const Icon(Icons.crop, color: Colors.white),
              onPressed: _openCanvasCropPage,
            ),
            IconButton(
              icon: const Icon(Icons.grid_3x3, color: Colors.white),
              onPressed: _openGridEditorPage,
            ),

            // 정보: _toggleInfoPanel 호출
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
              // onPressed: _toggleInfoPanel,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdvancedRoiPicker(
                      imageBytes: _getConvertImage(
                        widget.imagePaths[_currentIndex],
                      ),
                    ),
                  ),
                );
                // setState(() => panelVisible = !panelVisible);
              },
            ),

            // 크롭 페이지
            // IconButton(
            //   icon: const Icon(
            //     Icons.text_snippet_outlined,
            //     color: Colors.white,
            //   ),
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (_) => PerspectiveCropScreen(
            //           imageBytes: _getConvertImage(
            //             widget.imagePaths[_currentIndex],
            //           ),
            //         ),
            //       ),
            //     );
            //     // setState(() => panelVisible = !panelVisible);
            //   },
            // ),
            IconButton(
              icon: const Icon(
                Icons.text_snippet_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageSimplificationScreen(
                      imageBytes: _getConvertImage(
                        widget.imagePaths[_currentIndex],
                      ),
                    ),
                  ),
                );
                // setState(() => panelVisible = !panelVisible);
              },
            ),
          ],
        ),
      ),
    );
  }

  Uint8List _getConvertImage(String imagePath) {
    final mat = cv.imread(imagePath);
    final (success, bytes) = cv.imencode(".jpg", mat);

    mat.dispose();
    return bytes;
  }
}
