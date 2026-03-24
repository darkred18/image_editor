// // import 'dart:io';
// // import 'dart:typed_data';
// // import 'package:flutter/material.dart';
// // import 'package:image_editor/edit/image_info.dart';
// // import 'package:image_editor/screens/crop_image.dart';
// // import 'package:image_editor/screens/edit_screen.dart';
// // import 'package:image_editor/screens/test_remote.dart';
// // // import 'package:image_editor/screens/quad_crop_test.dart';
// // import 'package:photo_view/photo_view.dart';
// // import 'package:photo_view/photo_view_gallery.dart';

// // class DetailScreen extends StatefulWidget {
// //   final List<String> imagePaths;
// //   final int initialIndex;

// //   const DetailScreen({
// //     super.key,
// //     required this.imagePaths,
// //     required this.initialIndex,
// //   });

// //   @override
// //   State<DetailScreen> createState() => _DetailScreenState();
// // }

// // class _DetailScreenState extends State<DetailScreen> {
// //   late PageController _pageController;
// //   late int _currentIndex;
// //   double _dragStart = 0;
// //   double _lastDelta = 0;
// //   bool _isDragging = false;

// //   bool showInfo = false;
// //   ImageInfoData? info;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _currentIndex = widget.initialIndex;
// //     _pageController = PageController(initialPage: _currentIndex);
// //   }

// //   @override
// //   void dispose() {
// //     _pageController.dispose();
// //     super.dispose();
// //   }

// //   void _handleHorizontalDragStart(DragStartDetails details) {
// //     _dragStart = details.globalPosition.dx;
// //     _lastDelta = 0;
// //     _isDragging = true;
// //   }

// //   void _handleHorizontalDragUpdate(DragUpdateDetails details) {
// //     if (!_isDragging) return;

// //     final delta = details.globalPosition.dx - _dragStart;

// //     // 처음 움직인 방향을 기억
// //     if (_lastDelta == 0) {
// //       _lastDelta = delta;
// //     }

// //     // 반대 방향 움직임은 무시 (즉, 방향 반전 방지)
// //     if ((_lastDelta > 0 && delta < 0) || (_lastDelta < 0 && delta > 0)) {
// //       return;
// //     }

// //     // PageView 스크롤을 수동으로 이동
// //     _pageController.position.moveTo(_pageController.offset - details.delta.dx);
// //   }

// //   void _handleHorizontalDragEnd(DragEndDetails details) {
// //     _isDragging = false;
// //     final page = _pageController.page ?? 0;
// //     final currentPage = page.floor();
// //     final progress = page - currentPage;

// //     // 반쯤 이상 넘겼으면 다음 페이지로
// //     if (progress > 0.5) {
// //       _pageController.nextPage(
// //         duration: const Duration(milliseconds: 250),
// //         curve: Curves.easeOut,
// //       );
// //     } else if (progress < 0.5 && progress > 0.0) {
// //       _pageController.previousPage(
// //         duration: const Duration(milliseconds: 250),
// //         curve: Curves.easeOut,
// //       );
// //     } else {
// //       _pageController.animateToPage(
// //         currentPage,
// //         duration: const Duration(milliseconds: 250),
// //         curve: Curves.easeOut,
// //       );
// //     }
// //   }

// //   // 원본 이미지 데이터(Uint8List)가 준비된 상태라고 가정합니다.
// //   // Uint8List originalImageBytes = ...;

// //   void _openCanvasCropPage(BuildContext context) async {
// //     final Uint8List bytes = await File(
// //       widget.imagePaths[_currentIndex],
// //     ).readAsBytes();
// //     // MaterialPageRoute를 사용하여 새로운 Route를 생성하고, 스택에 push합니다.
// //     final croppedImageBytes = await Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => CanvasCropPage(
// //           // 새로운 캔버스 페이지에 원본 이미지 데이터를 전달합니다.
// //           imageBytes: bytes,
// //         ),
// //       ),
// //     );

// //     // CanvasCropPage에서 작업 완료 후 결과가 돌아오면 실행됩니다.
// //     if (croppedImageBytes != null && croppedImageBytes is Uint8List) {
// //       // 여기에 편집된 이미지 데이터(croppedImageBytes)를 처리하는 로직을 작성합니다.
// //       print('✅ 이미지 편집 완료. 이전 화면이 다시 나타났습니다.');
// //     } else {
// //       print('❌ 편집이 취소되었습니다.');
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return PopScope(
// //       // ✅ 제스처나 시스템 뒤로가기 모두 차단
// //       canPop: false,
// //       onPopInvokedWithResult: (didPop, result) {
// //         // 시스템이 뒤로가기를 시도해도 무시
// //         if (!didPop) return;
// //       },
// //       child: Scaffold(
// //         backgroundColor: Colors.black,
// //         appBar: AppBar(
// //           backgroundColor: Colors.black,
// //           elevation: 0,
// //           leading: IconButton(
// //             icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
// //             onPressed: () => Navigator.pop(context),
// //           ),
// //           centerTitle: true,
// //           title: Text(
// //             '${_currentIndex + 1} / ${widget.imagePaths.length}',
// //             style: const TextStyle(color: Colors.white),
// //           ),
// //         ),
// //         body: Stack(
// //           children: [
// //             GestureDetector(
// //               onHorizontalDragStart: _handleHorizontalDragStart,
// //               onHorizontalDragUpdate: _handleHorizontalDragUpdate,
// //               onHorizontalDragEnd: _handleHorizontalDragEnd,
// //               child: PhotoViewGallery.builder(
// //                 itemCount: widget.imagePaths.length,
// //                 pageController: _pageController,
// //                 onPageChanged: (index) => setState(() => _currentIndex = index),
// //                 builder: (context, index) {
// //                   final imagePath = widget.imagePaths[index];
// //                   return PhotoViewGalleryPageOptions(
// //                     imageProvider: FileImage(File(imagePath)),
// //                     minScale: PhotoViewComputedScale.contained,
// //                     maxScale: PhotoViewComputedScale.covered * 3.0,
// //                     heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
// //                   );
// //                 },
// //                 scrollPhysics: const BouncingScrollPhysics(),
// //                 backgroundDecoration: const BoxDecoration(color: Colors.black),
// //               ),
// //             ),
// //             // ★ BottomAppBar 위에 올라오는 패널
// //             AnimatedPositioned(
// //               duration: Duration(milliseconds: 300),
// //               curve: Curves.easeInOut,
// //               left: 0,
// //               right: 0,
// //               bottom: showInfo ? 0 : -180, // ← 숨겨졌다가 올라옴
// //               child: Container(
// //                 height: 180,
// //                 padding: EdgeInsets.all(16),
// //                 decoration: BoxDecoration(
// //                   color: Colors.black87,
// //                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //                 ),
// //                 child: info == null
// //                     ? SizedBox()
// //                     : Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             "Name: ${info!.fileName}",
// //                             style: TextStyle(color: Colors.white),
// //                           ),
// //                           SizedBox(height: 6),
// //                           Text(
// //                             "Size: ${info!.fileSize}",
// //                             style: TextStyle(color: Colors.white),
// //                           ),
// //                           SizedBox(height: 6),
// //                           Text(
// //                             "Resolution: ${info!.width} x ${info!.height}",
// //                             style: TextStyle(color: Colors.white),
// //                           ),
// //                         ],
// //                       ),
// //               ),
// //             ),
// //           ],
// //         ),
// //         bottomNavigationBar: BottomAppBar(
// //           color: Colors.black54,
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //             children: [
// //               IconButton(
// //                 icon: const Icon(Icons.crop, color: Colors.white),
// //                 onPressed: () {
// //                   _openCanvasCropPage(context);
// //                 },
// //               ),
// //               IconButton(
// //                 icon: const Icon(Icons.share, color: Colors.white),
// //                 onPressed: () async {
// //                   final Uint8List bytes = await File(
// //                     widget.imagePaths[_currentIndex],
// //                   ).readAsBytes();
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (_) => ImageEditorPage(imageBytes: bytes),
// //                     ),
// //                   );
// //                 },
// //               ),
// //               IconButton(
// //                 icon: const Icon(
// //                   Icons.info_outline_rounded,
// //                   color: Colors.white,
// //                 ),
// //                 onPressed: () async {
// //                   final data = await getImageInfo(
// //                     widget.imagePaths[_currentIndex],
// //                   );
// //                   setState(() {
// //                     info = data;
// //                     showInfo = !showInfo;
// //                   });
// //                 },
// //               ),
// //               IconButton(
// //                 icon: const Icon(
// //                   Icons.text_snippet_outlined,
// //                   color: Colors.white,
// //                 ),
// //                 onPressed: () {
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(builder: (_) => RemotePage()),
// //                   );
// //                 },
// //               ),

// //               // 아래에서 올라오는 패널
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   // @override
// //   // Widget build(BuildContext context) {
// //   //   return Scaffold(
// //   //     backgroundColor: Colors.black,
// //   //     appBar: AppBar(
// //   //       backgroundColor: Colors.black,
// //   //       title: Text('${_currentIndex + 1} / ${widget.imagePaths.length}'),
// //   //     ),
// //   //     body: PageView.builder(
// //   //       controller: _pageController,
// //   //       itemCount: widget.imagePaths.length,
// //   //       onPageChanged: (index) => setState(() => _currentIndex = index),
// //   //       itemBuilder: (context, index) {
// //   //         return InteractiveViewer(
// //   //           child: Image.asset((widget.imagePaths[index])),
// //   //         );
// //   //       },
// //   //     ),
// //   //     bottomNavigationBar: BottomAppBar(
// //   //       color: Colors.black54,
// //   //       child: Row(
// //   //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //   //         children: [
// //   //           IconButton(
// //   //             icon: const Icon(Icons.edit, color: Colors.white),
// //   //             onPressed: () {
// //   //               Navigator.push(
// //   //                 context,
// //   //                 MaterialPageRoute(
// //   //                   builder: (_) =>
// //   //                       EditScreen(imagePath: widget.imagePaths[_currentIndex]),
// //   //                 ),
// //   //               );
// //   //             },
// //   //           ),
// //   //           IconButton(
// //   //             icon: const Icon(Icons.share, color: Colors.white),
// //   //             onPressed: () {},
// //   //           ),
// //   //           IconButton(
// //   //             icon: const Icon(Icons.delete, color: Colors.white),
// //   //             onPressed: () {},
// //   //           ),
// //   //         ],
// //   //       ),
// //   //     ),
// //   //   );
// //   // }
// // }

// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// // import 'package:image_editor/edit/image_info.dart'; // 누락된 파일, 가정하여 사용
// import 'package:image_editor/screens/crop_image.dart'; // CanvasCropPage 경로
// import 'package:image_editor/screens/edit_screen.dart'; // ImageEditorPage 경로
// import 'package:image_editor/screens/test_picker.dart';
// import 'package:image_editor/screens/test_remote.dart'; // RemotePage 경로
// import 'package:image_editor/widgets/double_picker.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';

// // 임시 정의: 실제 프로젝트 파일에 맞춰 이 부분을 수정해야 합니다.
// class ImageInfoData {
//   final String fileName;
//   final String fileSize;
//   final int width;
//   final int height;
//   ImageInfoData(this.fileName, this.fileSize, this.width, this.height);
// }

// // 임시 함수: 파일을 읽어 정보를 가져온다고 가정
// Future<ImageInfoData> getImageInfo(String path) async {
//   await Future.delayed(const Duration(milliseconds: 100));
//   final file = File(path);
//   // 실제 파일 정보 로딩 로직 (크기, 해상도 등)이 여기에 들어갑니다.
//   return ImageInfoData(
//     file.path.split('/').last,
//     '${(await file.length()) / 1024} KB',
//     1920, // 임시값
//     1080, // 임시값
//   );
// }

// class DetailScreen extends StatefulWidget {
//   final List<String> imagePaths;
//   final int initialIndex;

//   const DetailScreen({
//     super.key,
//     required this.imagePaths,
//     required this.initialIndex,
//   });

//   @override
//   State<DetailScreen> createState() => _DetailScreenState();
// }

// class _DetailScreenState extends State<DetailScreen> {
//   late PageController _pageController;
//   late int _currentIndex;

//   // 드래그 관련 불필요한 상태 변수 제거
//   // double _dragStart = 0;
//   // double _lastDelta = 0;
//   // bool _isDragging = false;

//   bool showInfo = false;
//   ImageInfoData? info;

//   @override
//   void initState() {
//     super.initState();

//     _currentIndex = widget.initialIndex;
//     _pageController = PageController(initialPage: _currentIndex);
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   // --- 유틸리티 함수: 현재 이미지 바이트 로딩 ---
//   Future<Uint8List> _getCurrentImageBytes() async {
//     final imagePath = widget.imagePaths[_currentIndex];
//     return await File(imagePath).readAsBytes();
//   }

//   // --- 캔버스 편집 페이지 열기 및 결과 처리 ---
//   void _openCanvasCropPage() async {
//     // 1. 현재 선택된 이미지의 바이트 데이터를 로드
//     final Uint8List originalBytes = await _getCurrentImageBytes();

//     // 2. CanvasCropPage를 덮어 씌우며(push) 열고, 결과(croppedImageBytes)를 기다립니다.
//     final croppedImageBytes = await Navigator.push(
//       // ignore: use_build_context_synchronously
//       context,
//       PageRouteBuilder(
//         transitionDuration: Duration(milliseconds: 250),
//         pageBuilder: (_, __, ___) => CanvasCropPage(imageBytes: originalBytes),
//         transitionsBuilder: (_, animation, __, child) {
//           return FadeTransition(opacity: animation, child: child);
//         },
//       ),
//       // MaterialPageRoute(
//       //   builder: (context) => CanvasCropPage(imageBytes: originalBytes),
//       // ),
//     );

//     // 3. CanvasCropPage에서 Navigator.pop으로 돌아왔을 때 결과 처리
//     if (croppedImageBytes != null && croppedImageBytes is Uint8List) {
//       // ✅ 이미지 편집 완료 후 처리 로직
//       // *주의: 현재는 List<String> imagePaths를 사용하므로,
//       // 편집된 이미지를 저장하고 해당 경로를 업데이트하는 추가 로직이 필요합니다.
//       print('✅ 이미지 편집 완료. 바이트 데이터 수신.');

//       // 만약 편집된 이미지를 즉시 갤러리에서 보여주려면,
//       // 이 시점에서 파일을 임시 저장하고 widget.imagePaths를 업데이트해야 합니다.
//     } else {
//       print('❌ 편집이 취소되었습니다.');
//     }
//   }

//   // --- ImageEditorPage 열기 ---
//   void _openImageEditorPage() async {
//     final Uint8List bytes = await _getCurrentImageBytes();
//     final List<String> _fruits1 = ['사과', '바나나', '딸기', '포도', '오렌지', '자두'];
//     final List<String> _fruits2 = ['키위', '망고', '수박', '멜론', '복숭아', '블루베리'];

//     final List<List<String>> items = [_fruits1, _fruits2];
//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         transitionDuration: Duration(milliseconds: 300),
//         pageBuilder: (_, __, ___) => DoublePicker(items: items),
//         transitionsBuilder: (_, animation, __, child) {
//           return FadeTransition(
//             opacity: animation,
//             child: ScaleTransition(
//               scale: Tween<double>(begin: 0.98, end: 1.0).animate(
//                 CurvedAnimation(parent: animation, curve: Curves.easeOut),
//               ),
//               child: child,
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // --- 정보 패널 토글 ---
//   void _toggleInfoPanel() async {
//     final data = await getImageInfo(widget.imagePaths[_currentIndex]);
//     setState(() {
//       info = data;
//       showInfo = !showInfo;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // GestureDetector 드래그 로직을 제거하고 PhotoViewGallery의 기본 스크롤을 사용
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: Text(
//           '${_currentIndex + 1} / ${widget.imagePaths.length}',
//           style: const TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Stack(
//         children: [
//           // PhotoViewGallery를 사용하여 이미지 스크롤 및 확대/축소 관리
//           PhotoViewGallery.builder(
//             itemCount: widget.imagePaths.length,
//             pageController: _pageController,
//             onPageChanged: (index) => setState(() => _currentIndex = index),
//             builder: (context, index) {
//               final imagePath = widget.imagePaths[index];
//               return PhotoViewGalleryPageOptions(
//                 imageProvider: FileImage(File(imagePath)),
//                 minScale: PhotoViewComputedScale.contained,
//                 maxScale: PhotoViewComputedScale.covered * 3.0,
//                 heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
//               );
//             },
//             scrollPhysics: const BouncingScrollPhysics(),
//             backgroundDecoration: const BoxDecoration(color: Colors.black),
//           ),

//           // ★ 정보 패널
//           AnimatedPositioned(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//             left: 0,
//             right: 0,
//             bottom: showInfo ? 0 : -180, // ← 숨겨졌다가 올라옴
//             child: Container(
//               height: 180,
//               padding: const EdgeInsets.all(16),
//               decoration: const BoxDecoration(
//                 color: Colors.black87,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: info == null
//                   ? const Center(child: CircularProgressIndicator()) // 정보 로딩 중
//                   : Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Name: ${info!.fileName}",
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           "Size: ${info!.fileSize}",
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           "Resolution: ${info!.width} x ${info!.height}",
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomAppBar(
//         height: 120,
//         color: Colors.black54,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             // 캔버스 크롭: _openCanvasCropPage 호출
//             IconButton(
//               icon: const Icon(Icons.crop, color: Colors.white),
//               onPressed: _openCanvasCropPage,
//             ),

//             // 일반 편집: _openImageEditorPage 호출
//             IconButton(
//               icon: const Icon(Icons.share, color: Colors.white),
//               onPressed: _openImageEditorPage,
//             ),

//             // 정보: _toggleInfoPanel 호출
//             IconButton(
//               icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
//               onPressed: _toggleInfoPanel,
//             ),

//             // 리모트 페이지
//             IconButton(
//               icon: const Icon(
//                 Icons.text_snippet_outlined,
//                 color: Colors.white,
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => RemotePage()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
