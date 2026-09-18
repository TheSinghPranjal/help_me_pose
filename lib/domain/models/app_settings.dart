import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// User-configurable preferences, persisted locally and never synced
/// anywhere off-device.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultOverlayOpacity = AppConstants.defaultOverlayOpacity,
    this.mirrorFrontCamera = false,
    this.hapticFeedbackEnabled = true,
    this.autoSaveAfterCapture = true,
  });

  final ThemeMode themeMode;
  final double defaultOverlayOpacity;

  /// When true, the saved (not just previewed) front-camera photo is
  /// mirrored to match what the user saw in the viewfinder.
  final bool mirrorFrontCamera;
  final bool hapticFeedbackEnabled;

  /// When true, a captured photo is written to the gallery immediately;
  /// when false, the user must tap Save on the preview screen.
  final bool autoSaveAfterCapture;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? defaultOverlayOpacity,
    bool? mirrorFrontCamera,
    bool? hapticFeedbackEnabled,
    bool? autoSaveAfterCapture,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultOverlayOpacity:
          defaultOverlayOpacity ?? this.defaultOverlayOpacity,
      mirrorFrontCamera: mirrorFrontCamera ?? this.mirrorFrontCamera,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      autoSaveAfterCapture: autoSaveAfterCapture ?? this.autoSaveAfterCapture,
    );
  }
}
