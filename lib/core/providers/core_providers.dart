import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/capture_repository.dart';
import '../../data/repositories/pose_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/camera/camera_service.dart';
import '../../services/filters/photo_filter_service.dart';
import '../../services/media/media_save_service.dart';
import '../../services/permissions/permission_service.dart';
import '../../services/storage/local_storage_service.dart';

/// Provided a concrete value in `main()` once async initialization
/// (SharedPreferences) completes, before [ProviderScope] is built.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
    'localStorageServiceProvider must be overridden in main()',
  );
});

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());

final mediaSaveServiceProvider = Provider<MediaSaveService>(
  (ref) => MediaSaveService(),
);

final photoFilterServiceProvider = Provider<PhotoFilterService>(
  (ref) => PhotoFilterService(),
);

final poseRepositoryProvider = Provider<PoseRepository>((ref) {
  return PoseRepository(ref.watch(localStorageServiceProvider));
});

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  return CaptureRepository(
    ref.watch(localStorageServiceProvider),
    ref.watch(photoFilterServiceProvider),
    ref.watch(mediaSaveServiceProvider),
    ref.watch(permissionServiceProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(localStorageServiceProvider));
});
