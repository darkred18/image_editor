// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dimension_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DimensionModel _$DimensionModelFromJson(Map<String, dynamic> json) =>
    DimensionModel(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      ratio: (json['ratio'] as num).toDouble(),
    );

Map<String, dynamic> _$DimensionModelToJson(DimensionModel instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'ratio': instance.ratio,
    };
