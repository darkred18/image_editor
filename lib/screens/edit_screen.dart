// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_editor/screens/core/canvas_core.dart';
// import 'package:image_editor/screens/core/image_editor_state.dart';
// // import 'package:image_editor/models/size_model.dart';

// class CanvasSizeEdit {
//   final double width;
//   final double height;
//   final double ratio;

//   CanvasSizeEdit({
//     required this.width,
//     required this.height,
//     required this.ratio,
//   });

//   factory CanvasSizeEdit.fromJson(Map<String, dynamic> json) {
//     return CanvasSizeEdit(
//       width: json['width'],
//       height: json['height'],
//       ratio: json['ratio'],
//     );
//   }
// }

// class EditorScreen extends StatefulWidget {
//   final Uint8List imageBytes;

//   const EditorScreen({super.key, required this.imageBytes});

//   @override
//   State<EditorScreen> createState() => _EditorScreenState();
// }

// class _EditorScreenState extends State<EditorScreen> {
//   late ImageEditorState state;

//   int tabIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     state = ImageEditorState(widget.imageBytes);
//   }

//   @override
//   void dispose() {
//     state.disposeAll();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           state.updateLayout(Size(constraints.maxWidth, constraints.maxHeight));

//           return AnimatedBuilder(
//             animation: state,
//             builder: (_, __) {
//               return Stack(
//                 children: [
//                   //----------------------------------
//                   // Core (이미지)
//                   //----------------------------------
//                   CanvasCore(state: state),

//                   //----------------------------------
//                   // ROI
//                   //----------------------------------
//                   RoiOverlay(state: state),

//                   //----------------------------------
//                   // 기능 Overlay
//                   //----------------------------------
//                   if (tabIndex == 1) GridOverlay(state: state),

//                   if (tabIndex == 2) PaintAnalysisOverlay(state: state),

//                   //----------------------------------
//                   // 하단 패널
//                   //----------------------------------
//                   Align(
//                     alignment: Alignment.bottomCenter,
//                     child: BottomPanel(state: state),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),

//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: tabIndex,
//         onTap: (i) {
//           setState(() {
//             tabIndex = i;
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.crop), label: "ROI"),
//           BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: "Grid"),
//           BottomNavigationBarItem(icon: Icon(Icons.palette), label: "유화"),
//         ],
//       ),
//     );
//   }
// }
