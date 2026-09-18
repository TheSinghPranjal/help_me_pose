import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../domain/models/filter_option.dart';

/// Bakes a [PhotoFilterType] into JPEG bytes using the `image` package.
///
/// This is only ever applied to the captured photograph, never to the pose
/// reference overlay — the overlay is rendered in a separate widget layer
/// and is never part of the capture pipeline at all.
class PhotoFilterService {
  /// Decodes, normalizes EXIF orientation into actual pixel data (so the
  /// saved file is never "sideways" regardless of how a device's sensor
  /// reported it), applies [type], and re-encodes as JPEG. Runs off the UI
  /// isolate since decode/encode of a full-resolution photo is expensive.
  Future<Uint8List> apply(Uint8List sourceBytes, PhotoFilterType type) {
    return compute(_applyFilterIsolate, _FilterJob(sourceBytes, type));
  }

  static Uint8List _applyFilterIsolate(_FilterJob job) {
    final decoded = img.decodeJpg(job.bytes);
    if (decoded == null) return job.bytes;
    final oriented = img.bakeOrientation(decoded);
    final filtered = _filtered(oriented, job.type);
    return img.encodeJpg(filtered, quality: 94);
  }

  static img.Image _filtered(img.Image src, PhotoFilterType type) {
    switch (type) {
      case PhotoFilterType.original:
        return src;
      case PhotoFilterType.vivid:
        return img.adjustColor(src, saturation: 1.45, contrast: 1.08);
      case PhotoFilterType.warm:
        return img.adjustColor(src, hue: 8, saturation: 1.12, gamma: 0.96);
      case PhotoFilterType.cool:
        return img.adjustColor(src, hue: -10, saturation: 1.05, gamma: 1.02);
      case PhotoFilterType.mono:
        return img.grayscale(src);
      case PhotoFilterType.noir:
        return img.adjustColor(img.grayscale(src), contrast: 1.25, gamma: 0.94);
      case PhotoFilterType.vintage:
        final sepia = img.sepia(img.Image.from(src), amount: 0.55);
        return img.adjustColor(sepia, contrast: 0.92, brightness: 1.02);
      case PhotoFilterType.soft:
        return img.adjustColor(
          src,
          contrast: 0.9,
          saturation: 0.92,
          brightness: 1.04,
        );
    }
  }
}

class _FilterJob {
  const _FilterJob(this.bytes, this.type);
  final Uint8List bytes;
  final PhotoFilterType type;
}
