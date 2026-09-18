import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

/// Visual transform applied to the pose reference overlay on the camera
/// screen. Purely presentational — never affects the captured photograph.
@immutable
class OverlaySettings {
  const OverlaySettings({
    this.opacity = AppConstants.defaultOverlayOpacity,
    this.scale = AppConstants.defaultOverlayScale,
    this.offset = Offset.zero,
    this.isAdjustMode = false,
  });

  final double opacity;
  final double scale;
  final Offset offset;

  /// When true, drag/pinch gestures on the camera screen manipulate the
  /// overlay instead of the camera zoom.
  final bool isAdjustMode;

  OverlaySettings copyWith({
    double? opacity,
    double? scale,
    Offset? offset,
    bool? isAdjustMode,
  }) {
    return OverlaySettings(
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
      isAdjustMode: isAdjustMode ?? this.isAdjustMode,
    );
  }

  /// Returns to centered position, default scale, and the given default
  /// opacity (the user's configured default, normally 10%).
  OverlaySettings resetTo(double defaultOpacity) =>
      OverlaySettings(opacity: defaultOpacity);

  @override
  bool operator ==(Object other) =>
      other is OverlaySettings &&
      other.opacity == opacity &&
      other.scale == scale &&
      other.offset == offset &&
      other.isAdjustMode == isAdjustMode;

  @override
  int get hashCode => Object.hash(opacity, scale, offset, isAdjustMode);
}
