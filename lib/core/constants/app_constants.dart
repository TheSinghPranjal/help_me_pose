/// App-wide constant values that are not simple UI tokens.
abstract final class AppConstants {
  static const String appName = 'Help me Pose';

  /// Default overlay opacity shown when a pose is first selected (10%).
  static const double defaultOverlayOpacity = 0.10;
  static const double minOverlayOpacity = 0.0;
  static const double maxOverlayOpacity = 1.0;

  static const double defaultOverlayScale = 1.0;
  static const double minOverlayScale = 0.4;
  static const double maxOverlayScale = 3.0;

  static const double minCameraZoom = 1.0;

  /// Album name used when saving captured photographs to the native gallery.
  static const String captureAlbumName = 'Help me Pose';

  static const String builtInPoseManifestAsset = 'assets/poses/manifest.json';

  static const String prefsOnboardingComplete = 'onboarding_complete';
  static const String prefsThemeMode = 'theme_mode';
  static const String prefsDefaultOverlayOpacity = 'default_overlay_opacity';
  static const String prefsMirrorFrontCamera = 'mirror_front_camera';
  static const String prefsHapticFeedback = 'haptic_feedback_enabled';
  static const String prefsAutoSaveAfterCapture = 'auto_save_after_capture';
  static const String prefsFavoritePoseIds = 'favorite_pose_ids';
  static const String prefsRecentPoseIds = 'recent_pose_ids';
  static const String prefsCustomPoses = 'custom_poses_v1';
  static const String prefsCustomCategories = 'custom_categories_v1';
  static const String prefsRecentCaptureIds = 'recent_capture_ids_v1';

  static const int maxRecentPoses = 20;
  static const int maxCustomPoseImportBatch = 30;
}
