import 'package:json_annotation/json_annotation.dart';
import 'dimension_model.dart'; // 위에서 정의한 DimensionModel 임포트

// 파일 이름에 맞게 .g.dart 파일 이름을 선언합니다.
part 'painting_data_model.g.dart';

@JsonSerializable()
class PaintingDataModel {
  // 키("F", "P", "M") 아래에 호수("1", "2"...)와 DimensionModel이 있는 맵 구조
  final Map<String, DimensionModel> F;
  final Map<String, DimensionModel> P;
  final Map<String, DimensionModel> M;

  PaintingDataModel({required this.F, required this.P, required this.M});

  factory PaintingDataModel.fromJson(Map<String, dynamic> json) =>
      _$PaintingDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$PaintingDataModelToJson(this);
}

class PaintColorModel {
  final String name;
  final String pigment;
  final List<double> lab;

  PaintColorModel({
    required this.name,
    required this.pigment,
    required this.lab,
  });

  factory PaintColorModel.fromJson(Map<String, dynamic> json) {
    return PaintColorModel(
      name: json['name'] ?? 'Unknown',
      pigment: json['pigment'] ?? 'Unknown',
      lab: (json['lab'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class MixResultModel {
  final PaintColorModel a;
  final PaintColorModel b;
  final PaintColorModel c;

  final double wa;
  final double wb;
  final double wc;

  final double distance;

  MixResultModel({
    required this.a,
    required this.b,
    required this.c,
    required this.wa,
    required this.wb,
    required this.wc,
    required this.distance,
  });
}

class MixResultModel2 {
  final List<PaintColorModel> paints;
  final List<double> weights;
  final double distance;

  MixResultModel2({
    required this.paints,
    required this.weights,
    required this.distance,
  });
}
