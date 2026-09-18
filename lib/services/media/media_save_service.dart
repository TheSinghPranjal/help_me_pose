import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import '../../core/constants/app_constants.dart';

/// Saves captured photographs to the device's native photo library so they
/// appear exactly like any other photo taken with the phone's camera.
///
/// This is the *only* place in the app that talks to `photo_manager`. The
/// in-app "Recent Captures" view intentionally does **not** read this data
/// back through `photo_manager` — it uses its own local cache/index (see
/// `CaptureRepository`) so it never needs broad photo-library *read*
/// permission, only the minimal "add" permission needed to write a photo.
class MediaSaveService {
  /// On Android, MediaStore's `RELATIVE_PATH` both files the photo under
  /// `Pictures` (so it shows in the default gallery app) and creates/uses a
  /// named album in one step.
  ///
  /// On iOS/macOS, the photo is saved straight to the main Photos library.
  /// Filing it into a separate named album there would additionally require
  /// full photo-library *read* access (to find or create that album) — this
  /// app deliberately only ever requests the minimal "add" permission, so no
  /// custom album is created on iOS/macOS; the photo is still fully visible
  /// in the standard Photos app.
  Future<AssetEntity> saveImage(Uint8List bytes, {required String filename}) {
    if (Platform.isAndroid) {
      return PhotoManager.editor.saveImage(
        bytes,
        filename: filename,
        title: filename,
        relativePath: 'Pictures/${AppConstants.captureAlbumName}',
      );
    }
    return PhotoManager.editor.saveImage(
      bytes,
      filename: filename,
      title: filename,
    );
  }
}
