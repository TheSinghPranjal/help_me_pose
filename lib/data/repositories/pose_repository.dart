import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/pose.dart';
import '../../domain/models/pose_category.dart';
import '../../services/storage/local_storage_service.dart';

/// Loads the bundled (built-in) pose library and manages the user's custom
/// pose library, favorites and recently-used poses. The built-in library is
/// strictly read-only; custom poses are copied into app storage so they
/// keep working even if the original gallery file is later moved or deleted.
class PoseRepository {
  PoseRepository(this._storage);

  final LocalStorageService _storage;
  static const _uuid = Uuid();

  List<PoseCategory> _builtInCategories = const [];
  List<Pose> _builtInPoses = const [];
  bool _manifestLoaded = false;

  Future<void> _ensureManifestLoaded() async {
    if (_manifestLoaded) return;
    final raw = await rootBundle.loadString(
      AppConstants.builtInPoseManifestAsset,
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final categoriesJson = decoded['categories'] as Map<String, dynamic>;
    _builtInCategories = categoriesJson.entries.map((entry) {
      final meta = entry.value as List<dynamic>;
      return PoseCategory(
        id: entry.key,
        title: meta[0] as String,
        description: meta[1] as String,
        isCustom: false,
      );
    }).toList();

    final posesJson = decoded['poses'] as List<dynamic>;
    _builtInPoses = posesJson.map((raw) {
      final json = raw as Map<String, dynamic>;
      return Pose(
        id: json['id'] as String,
        title: json['title'] as String,
        categoryId: json['category'] as String,
        imagePath: json['assetPath'] as String,
        thumbnailPath: json['thumbnailPath'] as String?,
        source: PoseSource.builtIn,
        tags: (json['tags'] as List<dynamic>).cast<String>(),
        attribution: '${json['source']} • ${json['license']}',
        isSvg: (json['assetPath'] as String).endsWith('.svg'),
      );
    }).toList();

    _manifestLoaded = true;
  }

  Future<List<PoseCategory>> builtInCategories() async {
    await _ensureManifestLoaded();
    return _builtInCategories;
  }

  Future<List<Pose>> builtInPoses() async {
    await _ensureManifestLoaded();
    return _builtInPoses;
  }

  List<PoseCategory> customCategories() {
    return _storage
        .getJsonList(AppConstants.prefsCustomCategories)
        .map(PoseCategory.fromJson)
        .toList();
  }

  Future<void> addCustomCategory(PoseCategory category) async {
    final current = customCategories();
    if (current.any((c) => c.id == category.id)) return;
    await _storage.setJsonList(AppConstants.prefsCustomCategories, [
      ...current.map((c) => c.toJson()),
      category.toJson(),
    ]);
  }

  /// Returns custom poses whose backing file still exists on disk, silently
  /// dropping (but not deleting the record of) ones whose file has vanished
  /// so the caller can surface a friendly "unavailable" state instead.
  List<Pose> customPoses({bool includeMissingFiles = true}) {
    final all = _storage
        .getJsonList(AppConstants.prefsCustomPoses)
        .map(Pose.fromJson)
        .toList();
    if (includeMissingFiles) return all;
    return all.where((pose) => File(pose.imagePath).existsSync()).toList();
  }

  bool isCustomPoseFileMissing(Pose pose) => !File(pose.imagePath).existsSync();

  Future<Pose> importCustomPose({
    required String sourceFilePath,
    required String title,
    required String categoryId,
    List<String> tags = const [],
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final posesDir = Directory(p.join(docsDir.path, 'custom_poses'));
    if (!posesDir.existsSync()) posesDir.createSync(recursive: true);

    final id = _uuid.v4();
    final ext = p.extension(sourceFilePath).isEmpty
        ? '.jpg'
        : p.extension(sourceFilePath);
    final destPath = p.join(posesDir.path, '$id$ext');
    final sourceFile = File(sourceFilePath);
    final destFile = await sourceFile.copy(destPath);

    final thumbPath = p.join(posesDir.path, '${id}_thumb.jpg');
    await _generateThumbnail(destFile.path, thumbPath);

    final pose = Pose(
      id: id,
      title: title,
      categoryId: categoryId,
      imagePath: destFile.path,
      thumbnailPath: thumbPath,
      source: PoseSource.custom,
      tags: tags,
      attribution: 'Imported from your device',
      createdAt: DateTime.now(),
    );

    final current = customPoses();
    await _storage.setJsonList(AppConstants.prefsCustomPoses, [
      ...current.map((p) => p.toJson()),
      pose.toJson(),
    ]);
    return pose;
  }

  Future<void> _generateThumbnail(String sourcePath, String destPath) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;
      final resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 480 : null,
        height: decoded.height >= decoded.width ? 480 : null,
      );
      await File(destPath).writeAsBytes(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      // Thumbnail generation is a nice-to-have; fall back to the full image.
    }
  }

  Future<void> updateCustomPose(Pose updated) async {
    final current = customPoses();
    final next = current
        .map((pose) => pose.id == updated.id ? updated : pose)
        .toList();
    await _storage.setJsonList(
      AppConstants.prefsCustomPoses,
      next.map((p) => p.toJson()).toList(),
    );
  }

  /// Deletes the custom pose record and its locally copied files. This never
  /// touches the original file the user picked from their system gallery.
  Future<void> deleteCustomPose(String poseId) async {
    final current = customPoses();
    final target = current
        .where((pose) => pose.id == poseId)
        .cast<Pose?>()
        .firstOrNull;
    final next = current.where((pose) => pose.id != poseId).toList();
    await _storage.setJsonList(
      AppConstants.prefsCustomPoses,
      next.map((p) => p.toJson()).toList(),
    );
    if (target != null) {
      await _deleteFileQuietly(target.imagePath);
      if (target.thumbnailPath != null) {
        await _deleteFileQuietly(target.thumbnailPath!);
      }
    }
    await _removeFromFavorites(poseId);
  }

  Future<void> _deleteFileQuietly(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Ignore: not critical if cleanup fails.
    }
  }

  Set<String> favoriteIds() =>
      _storage.getStringList(AppConstants.prefsFavoritePoseIds).toSet();

  Future<void> setFavorite(String poseId, bool isFavorite) async {
    final current = favoriteIds();
    if (isFavorite) {
      current.add(poseId);
    } else {
      current.remove(poseId);
    }
    await _storage.setStringList(
      AppConstants.prefsFavoritePoseIds,
      current.toList(),
    );
  }

  Future<void> _removeFromFavorites(String poseId) async {
    final current = favoriteIds()..remove(poseId);
    await _storage.setStringList(
      AppConstants.prefsFavoritePoseIds,
      current.toList(),
    );
  }

  List<String> recentPoseIds() =>
      _storage.getStringList(AppConstants.prefsRecentPoseIds);

  Future<void> markPoseUsed(String poseId) async {
    final current = recentPoseIds().where((id) => id != poseId).toList();
    current.insert(0, poseId);
    final trimmed = current.take(AppConstants.maxRecentPoses).toList();
    await _storage.setStringList(AppConstants.prefsRecentPoseIds, trimmed);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
