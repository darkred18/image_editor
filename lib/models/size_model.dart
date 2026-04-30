class CanvasSize {
  final double width;
  final double height;
  final double ratio;

  CanvasSize({required this.width, required this.height, required this.ratio});

  factory CanvasSize.fromJson(Map<String, dynamic> json) {
    return CanvasSize(
      width: json['width'],
      height: json['height'],
      ratio: json['ratio'],
    );
  }
}

class CanvasSizeModel {
  final double width;
  final double height;
  final double ratio;

  CanvasSizeModel({
    required this.width,
    required this.height,
    required this.ratio,
  });

  factory CanvasSizeModel.fromJson(Map<String, dynamic> json) {
    return CanvasSizeModel(
      width: json['width'],
      height: json['height'],
      ratio: json['ratio'],
    );
  }
}
