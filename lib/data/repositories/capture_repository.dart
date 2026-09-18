import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/app_exceptions.dart';
import '../../domain/models/captured_photo.dart';
import '../../domain/models/filter_option.dart';
import '../../services/filters/photo_filter_service.dart';
import '../../services/media/media_save_service.dart';
import '../../services/permissions/permission_service.dart';
import '../../services/storage/local_storage_service.dart';

/// Orchestrates the post-capture pipeline: apply the chosen filter, save the
/// result to the system photo gallery, and keep a small local cache + index
/// so the in-app "Recent Captures" list is fast and works offline.
class CaptureRepository {
  CaptureRepository(
    this._storage,
    this._filterService,
    this._mediaSaveService,
    this._permissionService,
  );

  final LocalStorageService _storage;
  final PhotoFilterService _filterService;
  final MediaSaveService _mediaSaveService;
  final PermissionService _permissionService;
  static const _uuid = Uuid();

  Future<CapturedPhoto> finalizeAndSave(
    Uint8List rawJpegBytes, {
    required PhotoFilterType filter,
    String? poseIdUsed,
  }) async {
    await _ensureSavePermission();
    final processedBytes = await _filterService.apply(rawJpegBytes, filter);

    final id = _uuid.v4();
    final filename = 'help_me_pose_$id.jpg';

    final asset = await _mediaSaveService.saveImage(
      processedBytes,
      filename: filename,
    );

    final cacheDir = await _capturesCacheDir();
    final cacheFile = File(p.join(cacheDir.path, filename));
    await cacheFile.writeAsBytes(processedBytes);

    final photo = CapturedPhoto(
      id: id,
      filePath: cacheFile.path,
      capturedAt: DateTime.now(),
      galleryAssetId: asset.id,
      poseIdUsed: poseIdUsed,
      width: asset.width,
      height: asset.height,
    );

    await _appendToIndex(photo);
    return photo;
  }

  Future<void> _ensureSavePermission() async {
    var status = await _permissionService.checkSavePhotoPermission();
    if (status == AppPermissionStatus.granted ||
        status == AppPermissionStatus.limited) {
      return;
    }
    status = await _permissionService.requestSavePhotoPermission();
    if (status != AppPermissionStatus.granted &&
        status != AppPermissionStatus.limited) {
      throw const PhotoPermissionDeniedException();
    }
  }

  Future<Directory> _capturesCacheDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'recent_captures_cache'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<void> _appendToIndex(CapturedPhoto photo) async {
    final current = recentCaptures();
    final next = [photo, ...current].take(500).toList();
    await _storage.setJsonList(
      AppConstants.prefsRecentCaptureIds,
      next.map((c) => c.toJson()).toList(),
    );
  }

  List<CapturedPhoto> recentCaptures() {
    return _storage
        .getJsonList(AppConstants.prefsRecentCaptureIds)
        .map(CapturedPhoto.fromJson)
        .toList();
  }

  /// Drops any cached-index entries whose local cache file was deleted
  /// externally, so the gallery gracefully self-heals rather than showing
  /// broken thumbnails.
  Future<List<CapturedPhoto>> recentCapturesVerified() async {
    final all = recentCaptures();
    final valid = all.where((c) => File(c.filePath).existsSync()).toList();
    if (valid.length != all.length) {
      await _storage.setJsonList(
        AppConstants.prefsRecentCaptureIds,
        valid.map((c) => c.toJson()).toList(),
      );
    }
    return valid;
  }
}
