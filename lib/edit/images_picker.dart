import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MultiImagePickerPage extends StatefulWidget {
  const MultiImagePickerPage({super.key});

  @override
  State<MultiImagePickerPage> createState() => _MultiImagePickerPageState();
}

class _MultiImagePickerPageState extends State<MultiImagePickerPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  Future<void> _pickImages() async {
    // ✅ 최신 image_picker API
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 85, // 선택적 (압축 품질)
      maxWidth: 2048, // 선택적 (리사이즈)
    );

    if (images.isNotEmpty) {
      setState(() {
        _images = images;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _pickImages, // ✅ 오른쪽 상단 버튼으로 이동
            tooltip: '사진 추가',
          ),
        ],
      ),
      body: _images.isEmpty
          ? Center(
              child: ElevatedButton(
                onPressed: _pickImages,
                child: const Text('사진 선택'),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // ✅ 가로 2개
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageDetailPage(
                          imagePaths: _images.map((e) => e.path).toList(),
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: _images[index].path,
                    child: Image.file(
                      File(_images[index].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ImageDetailPage extends StatelessWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const ImageDetailPage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: imagePaths[index],
                child: Image.file(File(imagePaths[index]), fit: BoxFit.contain),
              );
            },
          ),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
