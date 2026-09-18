import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../services/permissions/permission_service.dart';

final cameraPermissionProvider =
    AsyncNotifierProvider<CameraPermissionNotifier, AppPermissionStatus>(
      CameraPermissionNotifier.new,
    );

class CameraPermissionNotifier extends AsyncNotifier<AppPermissionStatus> {
  @override
  Future<AppPermissionStatus> build() {
    return ref.read(permissionServiceProvider).checkCamera();
  }

  Future<void> request() async {
    final result = await ref.read(permissionServiceProvider).requestCamera();
    state = AsyncData(result);
  }

  /// Re-checks status without prompting — used when the app resumes (e.g.
  /// after the user visits system Settings) since there is no direct
  /// callback for a permission change made outside the app.
  Future<void> refresh() async {
    final result = await ref.read(permissionServiceProvider).checkCamera();
    state = AsyncData(result);
  }
}
