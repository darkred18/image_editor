import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';

class ImageInfoData {
  final int width;
  final int height;
  final String fileSize;
  final String fileName;

  ImageInfoData({
    required this.width,
    required this.height,
    required this.fileSize,
    required this.fileName,
  });
}

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return '0 B';

  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (log(bytes) / log(k)).floor();

  return '${(bytes / pow(k, i)).toStringAsFixed(decimals)} ${sizes[i]}';
}

Future<ImageInfoData> getImageInfo(String path) async {
  final file = File(path);

  // 1) 파일 크기
  final size = await file.length(); // bytes

  // 2) 파일 이름
  final name = path.split("/").last;

  // 3) 이미지 실제 폭/높이
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final img = frame.image;

  return ImageInfoData(
    width: img.width,
    height: img.height,
    fileSize: formatBytes(size),
    fileName: name,
  );
}
