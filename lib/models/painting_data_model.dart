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
