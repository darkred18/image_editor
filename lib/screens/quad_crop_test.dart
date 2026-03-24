// import 'dart:convert';
// import 'dart:io';
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;

// class ImageMarkerPage extends StatefulWidget {
//   final String imagePath;
//   const ImageMarkerPage({super.key, required this.imagePath});

//   @override
//   State<ImageMarkerPage> createState() => _ImageMarkerPageState();
// }

// class _ImageMarkerPageState extends State<ImageMarkerPage> {
//   Uint8List? imageBytes;
//   img.Image? decodedImage;
//   String base64Image = '';

//   /// handles는 '정규화된' 좌표(0..1 범위)를 저장합니다.
//   /// 화면 크기가 바뀌어도 같은 상대 위치 유지.
//   List<Offset> handles = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadImage();
//   }

//   Future<void> _loadImage() async {
//     try {
//       final f = File(widget.imagePath);
//       if (!await f.exists()) {
//         debugPrint("File not found: ${widget.imagePath}");
//         _showSnack("파일을 찾을 수 없습니다.");
//         return;
//       }
//       final bytes = await f.readAsBytes();
//       base64Image = base64Encode(bytes);
//       final decoded = img.decodeImage(bytes);
//       if (decoded == null) {
//         debugPrint("decodeImage returned null for ${widget.imagePath}");
//         _showSnack("이미지 디코딩 실패 (지원되지 않는 포맷일 수 있습니다).");
//         return;
//       }

//       setState(() {
//         imageBytes = bytes;
//         decodedImage = decoded;
//         // 초기 핸들: 정규화 좌표(화면 표시에서 10%/90% 위치)
//         handles = [
//           Offset(0.1, 0.1),
//           Offset(0.9, 0.1),
//           Offset(0.9, 0.9),
//           Offset(0.1, 0.9),
//         ];
//       });

//       debugPrint("Image loaded: ${decoded.width} x ${decoded.height}");
//     } catch (e, st) {
//       debugPrint("Error loading image: $e\n$st");
//       _showSnack("이미지 로드 중 오류가 발생했습니다.");
//     }
//   }

//   void _showSnack(String message) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(message)));
//     });
//   }

//   /// 정규화된 좌표(normalized 0..1) -> 실제 이미지 픽셀 좌표 반환
//   Offset _normalizedToImagePixel(Offset normalized) {
//     final w = decodedImage!.width.toDouble();
//     final h = decodedImage!.height.toDouble();
//     return Offset(normalized.dx * w, normalized.dy * h);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (imageBytes == null || decodedImage == null) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('이미지 점 4개 (정상판)')),
//       body: Center(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             // 이미지 비율(가로/세로)
//             final aspect =
//                 decodedImage!.width / decodedImage!.height.toDouble();

//             // 표시할 너비는 부모 제약의 maxWidth 사용, 높이는 비율 유지
//             final displayW = constraints.maxWidth;
//             final displayH = displayW / aspect;

//             // 핸들을 화면 좌표로 매핑할 때 사용될 크기
//             final size = Size(displayW, displayH);

//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SizedBox(
//                   width: displayW,
//                   height: displayH,
//                   child: Stack(
//                     children: [
//                       // 이미지 (배경)
//                       Image.memory(
//                         imageBytes!,
//                         width: displayW,
//                         height: displayH,
//                         fit: BoxFit.fill,
//                       ),

//                       // 선 그리기 (화면 좌표로 변환하여 그려줌)
//                       CustomPaint(
//                         size: size,
//                         painter: _LinePainter(
//                           handles
//                               .map(
//                                 (h) => Offset(h.dx * displayW, h.dy * displayH),
//                               )
//                               .toList(),
//                         ),
//                       ),

//                       // 각 핸들 (드래그 가능)
//                       for (int i = 0; i < handles.length; i++)
//                         // 위치는 화면 좌표 (displayW/H * normalized)
//                         Positioned(
//                           left: handles[i].dx * displayW - 12,
//                           top: handles[i].dy * displayH - 12,
//                           child: GestureDetector(
//                             behavior: HitTestBehavior.translucent,
//                             onPanUpdate: (details) {
//                               // 안전한 지역 연산: screen coords -> clamp -> normalized
//                               final double curScreenX =
//                                   handles[i].dx * displayW;
//                               final double curScreenY =
//                                   handles[i].dy * displayH;

//                               double newScreenX = curScreenX + details.delta.dx;
//                               double newScreenY = curScreenY + details.delta.dy;

//                               // 안전하게 범위 제한 (math 사용)
//                               newScreenX = math.max(
//                                 0.0,
//                                 math.min(newScreenX, displayW),
//                               );
//                               newScreenY = math.max(
//                                 0.0,
//                                 math.min(newScreenY, displayH),
//                               );

//                               final newNorm = Offset(
//                                 newScreenX / displayW,
//                                 newScreenY / displayH,
//                               );

//                               setState(() {
//                                 handles[i] = newNorm;
//                               });
//                             },
//                             child: Container(
//                               width: 24,
//                               height: 24,
//                               alignment: Alignment.center,
//                               decoration: BoxDecoration(
//                                 color: Colors.red,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Colors.white,
//                                   width: 2,
//                                 ),
//                                 boxShadow: const [
//                                   BoxShadow(
//                                     color: Colors.black26,
//                                     blurRadius: 4,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 12),
//                 ElevatedButton(
//                   onPressed: () {
//                     List<Offset> realHandles = handles
//                         .map((e) => Offset.zero)
//                         .toList();
//                     // 화면 표시 크기를 기준으로 정규화->이미지 픽셀 좌표 출력
//                     debugPrint("📸 이미지 경로: ${widget.imagePath}");
//                     for (int i = 0; i < handles.length; i++) {
//                       realHandles[i] = _normalizedToImagePixel(handles[i]);
//                       debugPrint(
//                         "Point ${i + 1}: ${realHandles[i].dx.toStringAsFixed(2)}, ${realHandles[i].dy.toStringAsFixed(2)}",
//                       );
//                     }
//                     _showSnack("좌표가 콘솔에 출력되었습니다.");
//                   },
//                   child: const Text("이미지 경로 + 이미지 기준 좌표 출력"),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// /// 화면 좌표로 전달된 점들을 연결해주는 페인터
// class _LinePainter extends CustomPainter {
//   final List<Offset> pts;
//   const _LinePainter(this.pts);

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (pts.isEmpty) return;

//     final paint = Paint()
//       ..color = Colors.yellowAccent
//       ..strokeWidth = 2
//       ..style = PaintingStyle.stroke;

//     final path = Path()..moveTo(pts.first.dx, pts.first.dy);
//     for (var p in pts.skip(1)) path.lineTo(p.dx, p.dy);
//     if (pts.length == 4) path.close();
//     canvas.drawPath(path, paint);

//     // 점도 작게 시각화
//     final dotPaint = Paint()..color = Colors.red;
//     for (var p in pts) {
//       canvas.drawCircle(p, 4, dotPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _LinePainter old) => old.pts != pts;
// }
