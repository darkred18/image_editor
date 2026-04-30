import 'dart:math' as math;

import 'package:image_editor/models/painting_data_model.dart';

MixResultModel2 findBest2Mix(
  List<PaintColorModel> paints,
  List<double> target,
) {
  MixResultModel2? best;

  for (int i = 0; i < paints.length; i++) {
    for (int j = i + 1; j < paints.length; j++) {
      final p1 = paints[i];
      final p2 = paints[j];

      for (double w = 0; w <= 1; w += 0.05) {
        final mix = [
          p1.lab[0] * w + p2.lab[0] * (1 - w),
          p1.lab[1] * w + p2.lab[1] * (1 - w),
          p1.lab[2] * w + p2.lab[2] * (1 - w),
        ];

        final d = colorDistance(mix, target);

        if (best == null || d < best.distance) {
          best = MixResultModel2(
            paints: [p1, p2],
            weights: [w, 1 - w],
            distance: d,
          );
        }
      }
    }
  }

  return best!;
}

double colorDistance(List<double> a, List<double> b) {
  return math.sqrt(
    math.pow(a[0] - b[0] * 0.8, 2) +
        math.pow(a[1] - b[1], 2) +
        math.pow(a[2] - b[2], 2),
  );
}

MixResultModel2 findBest3Mix(
  List<PaintColorModel> paints,
  List<double> target,
) {
  MixResultModel2? best;

  for (int i = 0; i < paints.length; i++) {
    for (int j = i + 1; j < paints.length; j++) {
      for (int k = j + 1; k < paints.length; k++) {
        final p1 = paints[i];
        final p2 = paints[j];
        final p3 = paints[k];

        for (double w1 = 0; w1 <= 1; w1 += 0.2) {
          for (double w2 = 0; w2 <= 1 - w1; w2 += 0.2) {
            final w3 = 1 - w1 - w2;

            final mix = [
              p1.lab[0] * w1 + p2.lab[0] * w2 + p3.lab[0] * w3,
              p1.lab[1] * w1 + p2.lab[1] * w2 + p3.lab[1] * w3,
              p1.lab[2] * w1 + p2.lab[2] * w2 + p3.lab[2] * w3,
            ];

            final d = colorDistance(mix, target);

            if (best == null || d < best.distance) {
              best = MixResultModel2(
                paints: [p1, p2, p3],
                weights: [w1, w2, w3],
                distance: d,
              );
            }
          }
        }
      }
    }
  }

  return best!;
}
