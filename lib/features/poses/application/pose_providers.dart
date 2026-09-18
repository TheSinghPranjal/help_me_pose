import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../domain/models/pose.dart';
import '../../../domain/models/pose_category.dart';

final builtInCategoriesProvider = FutureProvider<List<PoseCategory>>((ref) {
  return ref.watch(poseRepositoryProvider).builtInCategories();
});

final builtInPosesProvider = FutureProvider<List<Pose>>((ref) {
  return ref.watch(poseRepositoryProvider).builtInPoses();
});

final customCategoriesProvider =
    NotifierProvider<CustomCategoriesNotifier, List<PoseCategory>>(
      CustomCategoriesNotifier.new,
    );

class CustomCategoriesNotifier extends Notifier<List<PoseCategory>> {
  @override
  List<PoseCategory> build() =>
      ref.read(poseRepositoryProvider).customCategories();

  Future<void> add(PoseCategory category) async {
    await ref.read(poseRepositoryProvider).addCustomCategory(category);
    state = ref.read(poseRepositoryProvider).customCategories();
  }
}

/// All categories a pose can belong to: built-in (read-only) plus any
/// custom categories the user has created for their own poses.
final allCategoriesProvider = Provider<AsyncValue<List<PoseCategory>>>((ref) {
  final builtIn = ref.watch(builtInCategoriesProvider);
  final custom = ref.watch(customCategoriesProvider);
  return builtIn.whenData((list) => [...list, ...custom]);
});

final customPosesProvider = NotifierProvider<CustomPosesNotifier, List<Pose>>(
  CustomPosesNotifier.new,
);

class CustomPosesNotifier extends Notifier<List<Pose>> {
  @override
  List<Pose> build() => ref.read(poseRepositoryProvider).customPoses();

  Future<Pose> importPose({
    required String sourceFilePath,
    required String title,
    required String categoryId,
    List<String> tags = const [],
  }) async {
    final pose = await ref
        .read(poseRepositoryProvider)
        .importCustomPose(
          sourceFilePath: sourceFilePath,
          title: title,
          categoryId: categoryId,
          tags: tags,
        );
    state = [...state, pose];
    return pose;
  }

  Future<void> update(Pose pose) async {
    await ref.read(poseRepositoryProvider).updateCustomPose(pose);
    state = [for (final p in state) p.id == pose.id ? pose : p];
  }

  Future<void> delete(String poseId) async {
    await ref.read(poseRepositoryProvider).deleteCustomPose(poseId);
    state = state.where((p) => p.id != poseId).toList();
  }
}

final favoritePoseIdsProvider =
    NotifierProvider<FavoritePoseIdsNotifier, Set<String>>(
      FavoritePoseIdsNotifier.new,
    );

class FavoritePoseIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.read(poseRepositoryProvider).favoriteIds();

  Future<void> toggle(String poseId) async {
    final isFavorite = !state.contains(poseId);
    await ref.read(poseRepositoryProvider).setFavorite(poseId, isFavorite);
    state = ref.read(poseRepositoryProvider).favoriteIds();
  }
}

final recentPoseIdsProvider =
    NotifierProvider<RecentPoseIdsNotifier, List<String>>(
      RecentPoseIdsNotifier.new,
    );

class RecentPoseIdsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ref.read(poseRepositoryProvider).recentPoseIds();

  Future<void> markUsed(String poseId) async {
    await ref.read(poseRepositoryProvider).markPoseUsed(poseId);
    state = ref.read(poseRepositoryProvider).recentPoseIds();
  }
}

/// The pose reference currently active as an overlay on the camera screen.
/// Selecting a pose is entirely optional — this starts as `null`.
final activePoseProvider = NotifierProvider<ActivePoseNotifier, Pose?>(
  ActivePoseNotifier.new,
);

class ActivePoseNotifier extends Notifier<Pose?> {
  @override
  Pose? build() => null;

  void select(Pose pose) {
    state = pose;
    ref.read(recentPoseIdsProvider.notifier).markUsed(pose.id);
  }

  void clear() => state = null;
}

/// Whether a custom pose's backing file has been deleted/moved outside the
/// app (e.g. the user cleared their gallery). Always false for built-in
/// poses, which are bundled assets.
final poseFileMissingProvider = Provider.family<bool, Pose>((ref, pose) {
  if (!pose.isCustom) return false;
  return ref.watch(poseRepositoryProvider).isCustomPoseFileMissing(pose);
});

/// Combined, ready-to-render list of every pose (built-in + custom).
final allPosesProvider = Provider<AsyncValue<List<Pose>>>((ref) {
  final builtIn = ref.watch(builtInPosesProvider);
  final custom = ref.watch(customPosesProvider);
  return builtIn.whenData((list) => [...list, ...custom]);
});
