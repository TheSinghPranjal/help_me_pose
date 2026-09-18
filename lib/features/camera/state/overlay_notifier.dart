import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/models/overlay_settings.dart';
import '../../settings/application/settings_notifier.dart';

final overlaySettingsProvider =
    NotifierProvider<OverlaySettingsNotifier, OverlaySettings>(
      OverlaySettingsNotifier.new,
    );

/// Manages the purely-visual transform (opacity/scale/position) applied to
/// the pose overlay on the camera screen. Deliberately isolated from
/// [CameraNotifier] so dragging the opacity slider never rebuilds the
/// camera preview or triggers any camera plugin calls.
class OverlaySettingsNotifier extends Notifier<OverlaySettings> {
  @override
  OverlaySettings build() {
    final defaultOpacity = ref
        .watch(settingsNotifierProvider)
        .defaultOverlayOpacity;
    return OverlaySettings(opacity: defaultOpacity);
  }

  void setOpacity(double value) {
    state = state.copyWith(
      opacity: value.clamp(
        AppConstants.minOverlayOpacity,
        AppConstants.maxOverlayOpacity,
      ),
    );
  }

  void setScale(double value) {
    state = state.copyWith(
      scale: value.clamp(
        AppConstants.minOverlayScale,
        AppConstants.maxOverlayScale,
      ),
    );
  }

  void translateBy(Offset delta) {
    state = state.copyWith(offset: state.offset.translate(delta.dx, delta.dy));
  }

  void setAdjustMode(bool value) => state = state.copyWith(isAdjustMode: value);

  void reset() {
    final defaultOpacity = ref
        .read(settingsNotifierProvider)
        .defaultOverlayOpacity;
    state = state.resetTo(defaultOpacity);
  }
}
