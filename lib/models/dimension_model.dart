import 'package:json_annotation/json_annotation.dart';

// [1] 이 부분이 에러의 원인이었던 'part' 지시자입니다.
//      'dimension_model.g.dart' 파일은 아직 존재하지 않지만, 곧 생성될 것입니다.
part 'dimension_model.g.dart';

@JsonSerializable()
class DimensionModel {
  // JSON의 값들이 소수점을 포함하므로 double 타입으로 정의합니다.
  final double width;
  final double height;
  final double ratio;

  DimensionModel({
    required this.width,
    required this.height,
    required this.ratio,
  });

  // [2] 자동 생성될 함수를 연결하는 팩토리 생성자
  factory DimensionModel.fromJson(Map<String, dynamic> json) =>
      _$DimensionModelFromJson(json);

  // (선택 사항) 객체를 다시 JSON으로 변환할 때 사용
  Map<String, dynamic> toJson() => _$DimensionModelToJson(this);
}
