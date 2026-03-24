import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show rootBundle;
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_editor/screens/detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.images});
  final List<XFile> images;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // List<String> imagePaths = [];
  // List<XFile> _images = [];
  // final ImagePicker _picker = ImagePicker();

  // Future<void> _pickImages() async {
  //   // ✅ 최신 image_picker API
  //   final List<XFile> images = await _picker.pickMultiImage(
  //     imageQuality: 85, // 선택적 (압축 품질)
  //     maxWidth: 2048, // 선택적 (리사이즈)
  //   );

  //   if (images.isNotEmpty) {
  //     setState(() {
  //       _images = images;
  //     });
  //   }
  // }

  // ----- assets/images 폴더의 이미지 경로들을 불러오는 비동기 함수 -----
  // Future<void> _loadImages() async {
  //   final images = await loadAssetImages(); // ✅ await로 실제 리스트 가져오기
  //   setState(() {
  //     imagePaths = images;
  //   });
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   // 이미지 로드
  //   _loadImages();
  // }
  // ----- assets/images 폴더의 이미지 경로들을 불러오는 비동기 함수 -----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('사진 선택', style: TextStyle(color: Colors.white70)),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add_photo_alternate_outlined),
        //     color: Colors.white70,
        //     onPressed: _pickImages, // ✅ 오른쪽 상단 버튼으로 이동
        //     tooltip: '사진 추가',
        //   ),
        // ],
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: ReorderableGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          dragStartDelay: const Duration(milliseconds: 300), // 길게 눌러야 드래그
          children: [
            for (int index = 0; index < widget.images.length; index++)
              GestureDetector(
                key: ValueKey(widget.images[index]),
                onTap: () {
                  print('runtimeType :  ${widget.images[index].runtimeType}');
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      // ✅ 전환 시간을 줄임 (기본은 약 300~400ms)
                      transitionDuration: const Duration(milliseconds: 500),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 500,
                      ),
                      pageBuilder: (_, __, ___) => DetailScreen(
                        imagePaths: widget.images.map((e) => e.path).toList(),
                        initialIndex: index,
                      ),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween(
                              begin: 0.98,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },

                child: Hero(
                  tag: widget.images[index],
                  flightShuttleBuilder:
                      (
                        flightContext,
                        animation,
                        direction,
                        fromHeroContext,
                        toHeroContext,
                      ) {
                        if (direction == HeroFlightDirection.pop) {
                          // ✅ 뒤로 갈 때는 Hero 애니메이션 생략하고 그냥 fade
                          return FadeTransition(
                            opacity: animation.drive(
                              Tween(begin: 0.1, end: 1.0),
                            ),
                            child: toHeroContext.widget,
                          );
                        }
                        return toHeroContext.widget;
                      },

                  child: Image.asset(
                    widget.images.map((e) => e.path).toList()[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = widget.images.removeAt(oldIndex);
              widget.images.insert(newIndex, item);
            });
          },
        ),
      ),
    );
  }
}

// Future<List<String>> loadAssetImages() async {
//   final manifestJson = await rootBundle.loadString('AssetManifest.json');
//   final Map<String, dynamic> manifest = json.decode(manifestJson);
//   final imagePaths = manifest.keys
//       .where((path) => path.startsWith('assets/images/'))
//       .toList();
//   return imagePaths;
// }

// Future<bool> isSimulator() async {
//   if (Platform.isIOS) {
//     final deviceInfo = DeviceInfoPlugin();
//     final iosInfo = await deviceInfo.iosInfo;
//     return !iosInfo.isPhysicalDevice; // true면 시뮬레이터
//   } else if (Platform.isAndroid) {
//     final deviceInfo = DeviceInfoPlugin();
//     final androidInfo = await deviceInfo.androidInfo;
//     return !androidInfo.isPhysicalDevice; // true면 에뮬레이터
//   }
//   return false; // iOS/Android 외 환경은 기본 false
// }
