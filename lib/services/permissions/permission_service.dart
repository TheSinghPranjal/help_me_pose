import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Result of a permission check/request, simplified to what the UI needs to
/// decide which state to render.
enum AppPermissionStatus {
  granted,
  limited,
  denied,
  permanentlyDenied,
  restricted,
}

extension on PermissionStatus {
  AppPermissionStatus toAppStatus() {
    if (isGranted) return AppPermissionStatus.granted;
    if (isLimited) return AppPermissionStatus.limited;
    if (isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (isRestricted) return AppPermissionStatus.restricted;
    return AppPermissionStatus.denied;
  }
}

/// Thin wrapper around `permission_handler` scoped to exactly the two
/// permissions this app needs: camera (for live preview + capture) and
/// photo library (only when saving/importing images). No microphone,
/// location, storage, or other permission is ever requested.
class PermissionService {
  Future<AppPermissionStatus> checkCamera() async {
    final status = await Permission.camera.status;
    return status.toAppStatus();
  }

  Future<AppPermissionStatus> requestCamera() async {
    final status = await Permission.camera.request();
    return status.toAppStatus();
  }

  /// Permission used right before the *first* gallery save, requested only
  /// at that point (never eagerly at launch). On iOS this requests "add
  /// only" access — no read access to the user's existing library is needed
  /// just to write a new photo. On Android it maps to `READ_MEDIA_IMAGES`
  /// (API 33+) or the legacy storage permission on older versions.
  Future<AppPermissionStatus> checkSavePhotoPermission() async {
    final permission = Platform.isIOS
        ? Permission.photosAddOnly
        : Permission.photos;
    return (await permission.status).toAppStatus();
  }

  Future<AppPermissionStatus> requestSavePhotoPermission() async {
    final permission = Platform.isIOS
        ? Permission.photosAddOnly
        : Permission.photos;
    return (await permission.request()).toAppStatus();
  }

  Future<bool> openSettings() => openAppSettings();
}
