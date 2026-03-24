// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'painting_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaintingDataModel _$PaintingDataModelFromJson(Map<String, dynamic> json) =>
    PaintingDataModel(
      F: (json['F'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, DimensionModel.fromJson(e as Map<String, dynamic>)),
      ),
      P: (json['P'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, DimensionModel.fromJson(e as Map<String, dynamic>)),
      ),
      M: (json['M'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, DimensionModel.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$PaintingDataModelToJson(PaintingDataModel instance) =>
    <String, dynamic>{'F': instance.F, 'P': instance.P, 'M': instance.M};
