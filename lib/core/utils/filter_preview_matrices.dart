import 'package:flutter/widgets.dart';

import '../../domain/models/filter_option.dart';

/// Fast, GPU-applied [ColorFilter] approximations of each [PhotoFilterType],
/// used purely for instant live preview while the user is choosing a filter
/// on the capture review screen. The authoritative, saved result is instead
/// produced pixel-by-pixel by `PhotoFilterService` — the two are only
/// required to look close, not to match exactly.
abstract final class FilterPreviewMatrices {
  static ColorFilter forType(PhotoFilterType type) {
    final values = switch (type) {
      PhotoFilterType.original => _identity,
      PhotoFilterType.vivid => _saturation(1.45),
      PhotoFilterType.warm => _translated(_saturation(1.12), 14, 4, -14),
      PhotoFilterType.cool => _translated(_saturation(1.05), -10, 0, 16),
      PhotoFilterType.mono => _saturation(0),
      PhotoFilterType.noir => _scaled(_saturation(0), 1.2, offset: -18),
      PhotoFilterType.vintage => _translated(_saturation(0.55), 18, 6, -18),
      PhotoFilterType.soft => _translated(
        _scaled(_saturation(0.9), 0.9),
        14,
        12,
        10,
      ),
    };
    return ColorFilter.matrix(values);
  }

  static const List<double> _identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  static List<double> _saturation(double sat) {
    const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
    final sr = (1 - sat) * lumR, sg = (1 - sat) * lumG, sb = (1 - sat) * lumB;
    return [
      sr + sat, sg, sb, 0, 0, //
      sr, sg + sat, sb, 0, 0, //
      sr, sg, sb + sat, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  static List<double> _translated(
    List<double> m,
    double dr,
    double dg,
    double db,
  ) {
    final result = List<double>.from(m);
    result[4] += dr;
    result[9] += dg;
    result[14] += db;
    return result;
  }

  static List<double> _scaled(
    List<double> m,
    double factor, {
    double offset = 0,
  }) {
    final result = List<double>.from(m);
    for (final row in [0, 1, 2]) {
      final base = row * 5;
      for (var i = 0; i < 3; i++) {
        result[base + i] *= factor;
      }
      result[base + 4] = result[base + 4] * factor + offset;
    }
    return result;
  }
}
