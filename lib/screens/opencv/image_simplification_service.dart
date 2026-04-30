// import 'dart:typed_data';
// import 'package:dartcv4/dartcv.dart' as cv;
// import 'package:flutter/material.dart';

// class SimplificationResult {
//   final Uint8List imageBytes;
//   final List<Color> palette;
//   const SimplificationResult({required this.imageBytes, required this.palette});
// }

// class ImageSimplificationService {
//   static Future<SimplificationResult> simplify({
//     required Uint8List imageBytes,
//     required int step,
//   }) async {
//     // 1. 이미지 디코딩
//     var src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
//     if (src.isEmpty) throw Exception('이미지 로드 실패');

//     // [중요] 메모리 방어: 이미지 사이즈가 너무 크면 800px 이하로 축소하여 연산 속도와 안정성 확보
//     if (src.cols > 800 || src.rows > 800) {
//       double scale = 800 / (src.cols > src.rows ? src.cols : src.rows);
//       var resized = cv.resize(src, (0, 0), fx: scale, fy: scale);
//       src.dispose();
//       src = resized;
//     }

//     // 2. 단계별 설정
//     int colorCount = (step == 1) ? 6 : (step == 2 ? 12 : 24);
//     double sigma = (step == 1) ? 150.0 : (step == 2 ? 75.0 : 30.0);
//     int bilateralD = (step == 1) ? 15 : 9;

//     // 3. Bilateral Filter (유화의 덩어리감 형성)
//     final blurred = cv.bilateralFilter(src, bilateralD, sigma, sigma);

//     // 4. K-Means 데이터 준비
//     // CV_32FC3로 변환하여 컬러 채널 유지
//     final reshaped = blurred.reshape(1, blurred.rows * blurred.cols);
//     final float32Data = reshaped.convertTo(cv.MatType.CV_32FC3);
//     reshaped.dispose();

//     // 5. K-Means 실행
//     final labels = cv.Mat.empty();
//     // (compactness, bestLabels, centers) 반환
//     final res = cv.kmeans(
//       float32Data,
//       colorCount,
//       labels,
//       (2 + 1, 10, 1.0), // 반복 횟수를 10회로 줄여 부하 감소
//       1, // 시도 횟수 감소
//       cv.KMEANS_PP_CENTERS,
//     );

//     final bestLabels = res.$2;
//     final centers = res.$3;

//     // 6. 팔레트 및 결과 이미지 생성
//     final centersU8 = centers.convertTo(cv.MatType.CV_8UC3);
//     final centerBytes = centersU8.data;

//     // Label 데이터를 안전하게 Dart List로 복사 (Native 접근 최소화)
//     final labelData = bestLabels.data.buffer.asInt32List();
//     final totalPixels = blurred.rows * blurred.cols;

//     final quantized = cv.Mat.zeros(
//       blurred.rows,
//       blurred.cols,
//       cv.MatType.CV_8UC3,
//     );
//     final qBytes = quantized.data;

//     for (int i = 0; i < totalPixels; i++) {
//       final clusterIdx = labelData[i];
//       // 유효 인덱스 체크 (안전 장치)
//       if (clusterIdx >= 0 && clusterIdx < colorCount) {
//         qBytes[i * 3 + 0] = centerBytes[clusterIdx * 3 + 0];
//         qBytes[i * 3 + 1] = centerBytes[clusterIdx * 3 + 1];
//         qBytes[i * 3 + 2] = centerBytes[clusterIdx * 3 + 2];
//       }
//     }

//     // 팔레트 생성
//     final palette = <Color>[];
//     for (int i = 0; i < colorCount; i++) {
//       palette.add(
//         Color.fromARGB(
//           255,
//           centerBytes[i * 3 + 2],
//           centerBytes[i * 3 + 1],
//           centerBytes[i * 3 + 0],
//         ),
//       );
//     }

//     // 7. 인코딩 및 메모리 해제 (매우 중요)
//     final (_, encoded) = cv.imencode('.jpg', quantized);

//     // 모든 Native 객체 해제
//     src.dispose();
//     blurred.dispose();
//     float32Data.dispose();
//     bestLabels.dispose();
//     centers.dispose();
//     centersU8.dispose();
//     labels.dispose();
//     quantized.dispose();

//     return SimplificationResult(imageBytes: encoded, palette: palette);
//   }
// }

import 'dart:typed_data';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';

class SimplificationResult {
  final Uint8List imageBytes;
  final List<Color> palette;
  const SimplificationResult({required this.imageBytes, required this.palette});
}

class ImageSimplificationService {
  static Future<Color> simplifyByROI({required Uint8List roiImageBytes}) async {
    cv.Mat? src;
    cv.Mat? resized;
    cv.Mat? blurred;
    try {
      src = cv.imdecode(roiImageBytes, cv.IMREAD_COLOR);
      if (src.isEmpty) return Colors.black;

      // 대표색 추출을 위해 축소 및 블러 처리
      resized = cv.resize(src, (10, 10), interpolation: cv.INTER_AREA);
      blurred = cv.gaussianBlur(resized, (5, 5), 0);
      final scalar = cv.mean(blurred);

      // BGR -> RGB 변환
      return Color.fromARGB(
        255,
        scalar.val[2].toInt(),
        scalar.val[1].toInt(),
        scalar.val[0].toInt(),
      );
    } catch (e) {
      debugPrint("에러 발생: $e");
      return Colors.black;
    } finally {
      src?.dispose();
      resized?.dispose();
      blurred?.dispose();
    }
  }

  // ROI 영역 자르기 함수 (OpenCV 활용)
  static Future<Uint8List?> cropROI({
    required Uint8List originalBytes,
    required Rect roiRect,
    required Size displaySize,
    required Size imagePixelSize,
  }) async {
    cv.Mat? src;
    cv.Mat? cropped;
    try {
      src = cv.imdecode(originalBytes, cv.IMREAD_COLOR);

      // 화면 좌표를 실제 이미지 픽셀 좌표로 변환
      double scaleX = imagePixelSize.width / displaySize.width;
      double scaleY = imagePixelSize.height / displaySize.height;

      int x = (roiRect.left * scaleX).toInt().clamp(
        0,
        imagePixelSize.width.toInt(),
      );
      int y = (roiRect.top * scaleY).toInt().clamp(
        0,
        imagePixelSize.height.toInt(),
      );
      int w = (roiRect.width * scaleX).toInt().clamp(
        1,
        imagePixelSize.width.toInt() - x,
      );
      int h = (roiRect.height * scaleY).toInt().clamp(
        1,
        imagePixelSize.height.toInt() - y,
      );

      cropped = src.region(cv.Rect(x, y, w, h));
      final (_, encoded) = cv.imencode(".jpg", cropped);
      return encoded;
    } catch (e) {
      return null;
    } finally {
      src?.dispose();
      cropped?.dispose();
    }
  }

  //   static Future<SimplificationResult> simplifyByROI({
  //   required Uint8List imageBytes,
  //   required double lowThreshold,
  //   required double highThreshold,
  // }) async {
  //   cv.Mat? src;
  //   cv.Mat? gray;
  //   cv.Mat? edges;
  //   cv.Mat? labels;
  //   cv.Mat? result;

  //   try {
  //     src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
  //     result = cv.Mat.zeros(src.rows, src.cols, cv.MatType.CV_8UC3);

  //     // 1. Canny로 엣지 추출
  //     gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
  //     var blurred = cv.gaussianBlur(gray, (3, 3), 0);
  //     edges = cv.canny(blurred, lowThreshold, highThreshold);

  //     // 2. 엣지 팽창 및 반전 (구역을 확실히 닫기 위함)
  //     var kernel = cv.getStructuringElement(cv.MORPH_RECT, (2, 2));
  //     var dilated = cv.dilate(edges, kernel);
  //     var inverted = cv.bitwiseNot(dilated); // 선이 0(검정), 배경이 255(흰색)

  //     // 3. 연결된 영역 찾기 (Labeling)
  //     // 각 닫힌 구역마다 고유 번호가 매겨진 행렬이 반환됩니다.
  //     labels = cv.Mat.empty();
  //     int count = cv.connectedComponents(inverted, labels);

  //     // 4. 영역별 평균색 계산 및 채우기
  //     final lData = labels.data.buffer.asInt32List();
  //     final sData = src.data;
  //     final rData = result.data;

  //     // 각 라벨별 [R합, G합, B합, 픽셀수] 저장용 리스트
  //     List<List<double>> stats = List.generate(count, (_) => [0.0, 0.0, 0.0, 0.0]);

  //     // 전체 순회하며 색상 합계 계산
  //     for (int i = 0; i < lData.length; i++) {
  //       int label = lData[i];
  //       stats[label][0] += sData[i * 3 + 0]; // B
  //       stats[label][1] += sData[i * 3 + 1]; // G
  //       stats[label][2] += sData[i * 3 + 2]; // R
  //       stats[label][3] += 1;
  //     }

  //     // 라벨별 평균색 계산
  //     List<List<int>> avgColors = stats.map((s) {
  //       if (s[3] == 0) return [0, 0, 0];
  //       return [(s[0] / s[3]).round(), (s[1] / s[3]).round(), (s[2] / s[3]).round()];
  //     }).toList();

  //     // 결과 이미지에 채우기
  //     for (int i = 0; i < lData.length; i++) {
  //       int label = lData[i];
  //       rData[i * 3 + 0] = avgColors[label][0];
  //       rData[i * 3 + 1] = avgColors[label][1];
  //       rData[i * 3 + 2] = avgColors[label][2];
  //     }

  //     final (_, encoded) = cv.imencode('.jpg', result);
  //     return SimplificationResult(imageBytes: encoded, palette: []);

  //   } finally {
  //     src?.dispose(); gray?.dispose(); edges?.dispose(); labels?.dispose();
  //   }
  // }

  static Future<SimplificationResult> simplifyByCannyLabels({
    required Uint8List imageBytes,
    required double lowThreshold,
    required double highThreshold,
  }) async {
    cv.Mat? src;
    cv.Mat? gray;
    cv.Mat? edges;
    cv.Mat? labels;
    cv.Mat? result;

    try {
      src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      result = cv.Mat.zeros(src.rows, src.cols, cv.MatType.CV_8UC3);

      // 1. Canny로 엣지 추출
      gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
      var blurred = cv.gaussianBlur(gray, (3, 3), 0);
      edges = cv.canny(blurred, lowThreshold, highThreshold);

      // 2. 엣지 팽창 및 반전 (구역을 확실히 닫기 위함)
      var kernel = cv.getStructuringElement(cv.MORPH_RECT, (2, 2));
      var dilated = cv.dilate(edges, kernel);
      var inverted = cv.bitwiseNOT(dilated); // 선이 0(검정), 배경이 255(흰색)

      // 3. 연결된 영역 찾기 (Labeling)
      // 각 닫힌 구역마다 고유 번호가 매겨진 행렬이 반환됩니다.
      labels = cv.Mat.empty();
      int count = cv.connectedComponents(
        inverted,
        labels,
        8,
        cv.MatType.CV_32S,
        cv.CCL_DEFAULT,
      );

      // 4. 영역별 평균색 계산 및 채우기
      final lData = labels.data.buffer.asInt32List();
      final sData = src.data;
      final rData = result.data;

      // 각 라벨별 [R합, G합, B합, 픽셀수] 저장용 리스트
      List<List<double>> stats = List.generate(
        count,
        (_) => [0.0, 0.0, 0.0, 0.0],
      );

      // 전체 순회하며 색상 합계 계산
      for (int i = 0; i < lData.length; i++) {
        int label = lData[i];
        stats[label][0] += sData[i * 3 + 0]; // B
        stats[label][1] += sData[i * 3 + 1]; // G
        stats[label][2] += sData[i * 3 + 2]; // R
        stats[label][3] += 1;
      }

      // 라벨별 평균색 계산
      List<List<int>> avgColors = stats.map((s) {
        if (s[3] == 0) return [0, 0, 0];
        return [
          (s[0] / s[3]).round(),
          (s[1] / s[3]).round(),
          (s[2] / s[3]).round(),
        ];
      }).toList();

      // 결과 이미지에 채우기
      for (int i = 0; i < lData.length; i++) {
        int label = lData[i];
        rData[i * 3 + 0] = avgColors[label][0];
        rData[i * 3 + 1] = avgColors[label][1];
        rData[i * 3 + 2] = avgColors[label][2];
      }

      final (_, encoded) = cv.imencode('.jpg', result);
      return SimplificationResult(imageBytes: encoded, palette: []);
    } finally {
      src?.dispose();
      gray?.dispose();
      edges?.dispose();
      labels?.dispose();
    }
  }

  static Future<SimplificationResult> simplify4({
    required Uint8List imageBytes,
    required int colorCount, // 파이썬의 K (8)
    required double sigmaColor, // 파이썬의 75
    required double sigmaSpace, // 파이썬의 75
  }) async {
    cv.Mat? src;
    cv.Mat? blurred;
    cv.Mat? data;
    cv.Mat? labels;
    cv.Mat? centers;
    cv.Mat? posterized;

    try {
      // 1. 이미지 디코딩
      src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);

      // 2. Bilateral Filter 적용 (d=9, sigmaColor, sigmaSpace)
      blurred = cv.bilateralFilter(src, 9, sigmaColor, sigmaSpace);

      // 3. K-Means를 위한 데이터 변환 (reshape & float32)
      final reshaped = blurred.reshape(1, blurred.rows * blurred.cols);
      data = reshaped.convertTo(cv.MatType.CV_32FC3);
      reshaped.dispose();

      // 4. K-Means 적용 (criteria 상수 직접 지정: 3은 COUNT + EPS)
      labels = cv.Mat.empty();
      final res = cv.kmeans(
        data,
        colorCount,
        labels,
        (3, 10, 1.0), // criteria: (type, maxCount, epsilon)
        10, // attempts
        cv.KMEANS_RANDOM_CENTERS,
      );

      // 5. 결과 재구성 (중심 색상으로 픽셀 대체)
      final centers8U = res.$3.convertTo(cv.MatType.CV_8UC3);
      final cBytes = centers8U.data; // 중심 색상들 (BGRBGR...)
      final lData = res.$2.data.buffer.asInt32List(); // 라벨 데이터 (어느 클러스터인지)

      posterized = cv.Mat.zeros(blurred.rows, blurred.cols, cv.MatType.CV_8UC3);
      final pBytes = posterized.data;

      // 파이썬의 centers[labels.flatten()] 역할을 하는 반복문
      for (int i = 0; i < lData.length; i++) {
        int clusterIdx = lData[i];
        pBytes[i * 3 + 0] = cBytes[clusterIdx * 3 + 0]; // Blue
        pBytes[i * 3 + 1] = cBytes[clusterIdx * 3 + 1]; // Green
        pBytes[i * 3 + 2] = cBytes[clusterIdx * 3 + 2]; // Red
      }

      // 팔레트 정보 추출 (UI 표시용)
      final palette = <Color>[];
      for (int i = 0; i < colorCount; i++) {
        palette.add(
          Color.fromARGB(
            255,
            cBytes[i * 3 + 2],
            cBytes[i * 3 + 1],
            cBytes[i * 3 + 0],
          ),
        );
      }

      final (_, encoded) = cv.imencode('.jpg', posterized);
      return SimplificationResult(imageBytes: encoded, palette: palette);
    } finally {
      // 6. 메모리 해제
      src?.dispose();
      blurred?.dispose();
      data?.dispose();
      labels?.dispose();
      posterized?.dispose();
    }
  }

  static Future<SimplificationResult> simplify3({
    required Uint8List imageBytes,
    required int colorCount, // 파이썬의 K
    required double sigmaColor,
    required double sigmaSpace,
  }) async {
    cv.Mat? src;
    cv.Mat? colorSmoothed;
    cv.Mat? colorSimplified;
    cv.Mat? edges;
    cv.Mat? finalResult;

    try {
      src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);

      // [1단계] 양방향 필터 (Bilateral Filter)
      colorSmoothed = cv.bilateralFilter(src, 9, sigmaColor, sigmaSpace);

      // [2단계] 색상 단순화 (K-Means) - 파이썬의 simplify_colors 함수 내용
      final reshaped = colorSmoothed.reshape(
        1,
        colorSmoothed.rows * colorSmoothed.cols,
      );
      final data = reshaped.convertTo(cv.MatType.CV_32FC3);

      final labels = cv.Mat.empty();
      final res = cv.kmeans(
        data,
        colorCount,
        labels,
        (3, 10, 1.0), // TERM_CRITERIA 상수 직접 지정
        10, // attempts
        cv.KMEANS_RANDOM_CENTERS,
      );

      final centers = res.$3.convertTo(cv.MatType.CV_8UC3);
      final cBytes = centers.data;
      final lData = res.$2.data.buffer.asInt32List();

      colorSimplified = cv.Mat.zeros(src.rows, src.cols, cv.MatType.CV_8UC3);
      final qBytes = colorSimplified.data;

      for (int i = 0; i < lData.length; i++) {
        int idx = lData[i];
        qBytes[i * 3 + 0] = cBytes[idx * 3 + 0];
        qBytes[i * 3 + 1] = cBytes[idx * 3 + 1];
        qBytes[i * 3 + 2] = cBytes[idx * 3 + 2];
      }

      // [3단계] 윤곽선 검출 및 합성 (파이썬 로직 그대로)
      final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
      final grayBlur = cv.medianBlur(gray, 7);
      // adaptiveThreshold (상수값: 0은 MEAN_C, 0은 BINARY, blockSize=9, C=2)
      final thresholded = cv.adaptiveThreshold(grayBlur, 255, 0, 0, 9, 2);
      edges = cv.cvtColor(thresholded, cv.COLOR_GRAY2BGR);

      // 비트 연산으로 합성 (color_simplified & edges)
      finalResult = cv.bitwiseAND(colorSimplified, edges);

      // 팔레트 생성용
      final palette = <Color>[];
      for (int i = 0; i < colorCount; i++) {
        palette.add(
          Color.fromARGB(
            255,
            cBytes[i * 3 + 2],
            cBytes[i * 3 + 1],
            cBytes[i * 3 + 0],
          ),
        );
      }

      final (_, encoded) = cv.imencode('.jpg', finalResult);
      return SimplificationResult(imageBytes: encoded, palette: palette);
    } finally {
      // 메모리 해제
      src?.dispose();
      colorSmoothed?.dispose();
      colorSimplified?.dispose();
      edges?.dispose();
      finalResult?.dispose();
    }
  }

  static Future<SimplificationResult> simplify2({
    required Uint8List imageBytes,
    required int colorCount,
    required double sigmaColor,
    required double sigmaSpace,
  }) async {
    cv.Mat? src;
    cv.Mat? lab;
    cv.Mat? blurred;
    cv.Mat? float32Data;
    cv.Mat? labels;
    cv.Mat? centers;
    cv.Mat? quantizedLab;
    cv.Mat? finalBgr;

    try {
      src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);

      // ── 1. 전처리: 양방향 필터 (색 경계 보존) ──
      blurred = cv.bilateralFilter(src, 9, sigmaColor, sigmaSpace);

      // ── 2. 핵심: BGR을 Lab 색공간으로 변환 (인간의 시각 기준) ──
      lab = cv.cvtColor(blurred, cv.COLOR_BGR2Lab);

      // ── 3. 데이터 구조화 ──
      final reshaped = lab.reshape(1, lab.rows * lab.cols);
      float32Data = reshaped.convertTo(cv.MatType.CV_32FC3);
      reshaped.dispose();

      // ── 4. K-Means (더 정밀하게 시도) ──
      labels = cv.Mat.empty();
      final res = cv.kmeans(
        float32Data,
        colorCount,
        labels,
        (3, 20, 0.1), // 정밀도와 반복 횟수 상향
        5, // attempts: 5번 시도해서 가장 좋은 결과 선택
        cv.KMEANS_PP_CENTERS,
      );
      final bestLabels = res.$2;
      centers = res.$3;

      // ── 5. Lab 공간에서 이미지 재구성 ──
      final centersF32 = centers; // 이미 32F 타입
      final lData = bestLabels.data.buffer.asInt32List();

      // 결과 전용 Mat (Lab 타입)
      quantizedLab = cv.Mat.zeros(
        blurred.rows,
        blurred.cols,
        cv.MatType.CV_32FC3,
      );
      final qData = quantizedLab.data.buffer.asFloat32List();
      final cData = centersF32.data.buffer.asFloat32List();

      for (int i = 0; i < lData.length; i++) {
        int clusterIdx = lData[i];
        qData[i * 3 + 0] = cData[clusterIdx * 3 + 0];
        qData[i * 3 + 1] = cData[clusterIdx * 3 + 1];
        qData[i * 3 + 2] = cData[clusterIdx * 3 + 2];
      }

      // ── 6. 최종 복원: Lab → BGR ──
      // 32F Lab를 8U BGR로 바꾸기 위해 변환
      final res8U = quantizedLab.convertTo(cv.MatType.CV_8UC3);
      finalBgr = cv.cvtColor(res8U, cv.COLOR_Lab2BGR);
      res8U.dispose();

      // 팔레트 추출 (BGR로 변환해서 저장)
      final centers8U = centers.convertTo(cv.MatType.CV_8UC3); // 임시 변환 필요

      final cBytes = centers8U.data;

      final quantized = cv.Mat.zeros(
        blurred.rows,
        blurred.cols,
        cv.MatType.CV_8UC3,
      );
      final qBytes = quantized.data;

      for (int i = 0; i < lData.length; i++) {
        final clusterIdx = lData[i];
        if (clusterIdx < colorCount) {
          qBytes[i * 3 + 0] = cBytes[clusterIdx * 3 + 0];
          qBytes[i * 3 + 1] = cBytes[clusterIdx * 3 + 1];
          qBytes[i * 3 + 2] = cBytes[clusterIdx * 3 + 2];
        }
      }
      final palette = <Color>[];
      for (int i = 0; i < colorCount; i++) {
        palette.add(
          Color.fromARGB(
            255,
            cBytes[i * 3 + 2],
            cBytes[i * 3 + 1],
            cBytes[i * 3 + 0],
          ),
        );
      }

      final (_, encoded) = cv.imencode('.jpg', finalBgr);
      return SimplificationResult(imageBytes: encoded, palette: palette);
    } finally {
      // 모든 Mat 해제
      src?.dispose();
      lab?.dispose();
      blurred?.dispose();
      float32Data?.dispose();
      labels?.dispose();
      centers?.dispose();
      quantizedLab?.dispose();
      finalBgr?.dispose();
    }
  }

  static Future<SimplificationResult> simplify({
    required Uint8List imageBytes,
    required int colorCount,
    required double sigmaColor,
    required double sigmaSpace,
  }) async {
    cv.Mat? src;
    cv.Mat? blurred;
    cv.Mat? float32Data;
    cv.Mat? labels;
    cv.Mat? centersU8;
    cv.Mat? quantized;

    try {
      src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      if (src.isEmpty) throw Exception('이미지 로딩 실패');

      // 메모리 보호를 위한 리사이징 (성능을 위해 600px 정도 추천)
      if (src.cols > 600 || src.rows > 600) {
        double scale = 600 / (src.cols > src.rows ? src.cols : src.rows);
        var resized = cv.resize(src, (0, 0), fx: scale, fy: scale);
        src.dispose();
        src = resized;
      }

      // 슬라이더에서 받아온 값 적용
      // bilateralFilter의 d값(지름)은 보통 5~9 정도가 적당합니다.
      blurred = cv.bilateralFilter(src, 9, sigmaColor, sigmaSpace);

      final reshaped = blurred.reshape(1, blurred.rows * blurred.cols);
      float32Data = reshaped.convertTo(cv.MatType.CV_32FC3);
      reshaped.dispose();

      labels = cv.Mat.empty();
      final res = cv.kmeans(
        float32Data,
        colorCount, // 슬라이더의 색상 개수
        labels,
        (3, 10, 1.0),
        1,
        cv.KMEANS_PP_CENTERS,
      );

      final bestLabels = res.$2;
      final centers = res.$3;

      centersU8 = centers.convertTo(cv.MatType.CV_8UC3);
      final cBytes = centersU8.data;
      final lData = bestLabels.data.buffer.asInt32List();

      quantized = cv.Mat.zeros(blurred.rows, blurred.cols, cv.MatType.CV_8UC3);
      final qBytes = quantized.data;

      for (int i = 0; i < lData.length; i++) {
        final clusterIdx = lData[i];
        if (clusterIdx < colorCount) {
          qBytes[i * 3 + 0] = cBytes[clusterIdx * 3 + 0];
          qBytes[i * 3 + 1] = cBytes[clusterIdx * 3 + 1];
          qBytes[i * 3 + 2] = cBytes[clusterIdx * 3 + 2];
        }
      }

      final palette = <Color>[];
      for (int i = 0; i < colorCount; i++) {
        palette.add(
          Color.fromARGB(
            255,
            cBytes[i * 3 + 2],
            cBytes[i * 3 + 1],
            cBytes[i * 3 + 0],
          ),
        );
      }

      final (_, encoded) = cv.imencode('.jpg', quantized);
      return SimplificationResult(imageBytes: encoded, palette: palette);
    } finally {
      src?.dispose();
      blurred?.dispose();
      float32Data?.dispose();
      labels?.dispose();
      centersU8?.dispose();
      quantized?.dispose();
    }
  }

  // ImageSimplificationService 클래스 내부 혹은 외부에 작성
  static Future<SimplificationResult> runSimplify(
    Map<String, dynamic> data,
  ) async {
    // 에러 방지를 위해 명시적으로 꺼내기
    final Uint8List? bytes = data['imageBytes'];
    if (bytes == null) throw Exception("이미지 데이터가 전달되지 않았습니다.");
    // 여기서 다시 순수 데이터를 꺼내서 본 함수 실행
    return await ImageSimplificationService.simplifyByCannyLabels(
      imageBytes: data['imageBytes'] as Uint8List,
      // colorCount: data['colorCount'] as int,
      lowThreshold: data['lowThreshold'] as double,
      highThreshold: data['highThreshold'] as double,
    );
  }
}
