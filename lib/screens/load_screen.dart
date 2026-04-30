import 'package:flutter/material.dart';
import 'package:image_editor/screens/gallery_screen.dart';
import 'package:image_picker/image_picker.dart';

class ImageEditMenu extends StatelessWidget {
  // final VoidCallback onImageLoad;
  // final VoidCallback onCrop;
  // final Function(double ratio) onRatioSelect;
  // final VoidCallback onSave;

  const ImageEditMenu({
    super.key,
    // required this.onImageLoad,
    // required this.onCrop,
    // required this.onRatioSelect,
    // required this.onSave,
  });

  void onCrop() {}
  void onSave() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('LOAD', style: TextStyle(color: Colors.white70)),

        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙 ⭐ 핵심!
              children: [
                _buildMenuItem(Icons.photo_library, "불러오기", () {
                  _pickImages(context);
                }),
                _buildMenuItem(Icons.crop, "자르기", onCrop),
                // _buildMenuItem(
                //   Icons.aspect_ratio,
                //   "비율설정",
                //   () => _showRatioPicker(context),
                // ),
                // _buildMenuItem(
                //   Icons.check_circle,
                //   "저장",
                //   onSave,
                //   color: Colors.blueAccent,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    // List<XFile> _images = [];
    final ImagePicker picker = ImagePicker();
    // ✅ 최신 image_picker API
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 85, // 선택적 (압축 품질)
      maxWidth: 2048, // 선택적 (리사이즈)
    );

    if (images.isNotEmpty) {
      // 비동기 작업 후 context가 여전히 유효한지 확인
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GalleryScreen(images: images)),
      );
    }
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showRatioPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A), // 하이테크 다크 배경
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "캔버스 비율 선택",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ratioButton(context, "1:1", 1.0),
                _ratioButton(context, "4:3", 4 / 3),
                _ratioButton(context, "16:9", 16 / 9),
                _ratioButton(context, "자유", 0.0),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _ratioButton(BuildContext context, String label, double ratio) {
    return OutlinedButton(
      onPressed: () {
        // onRatioSelect(ratio);
        // Navigator.pop(context);
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white24),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
