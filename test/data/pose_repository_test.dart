import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:help_me_pose/core/constants/app_constants.dart';
import 'package:help_me_pose/data/repositories/pose_repository.dart';
import 'package:help_me_pose/domain/models/pose_category.dart';
import 'package:help_me_pose/services/storage/local_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PoseRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('help_me_pose_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.create();
    repository = PoseRepository(storage);
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  group('favorites', () {
    test('starts empty and toggling adds/removes an id', () async {
      expect(repository.favoriteIds(), isEmpty);
      await repository.setFavorite('pose_1', true);
      expect(repository.favoriteIds(), {'pose_1'});
      await repository.setFavorite('pose_1', false);
      expect(repository.favoriteIds(), isEmpty);
    });
  });

  group('recently used poses', () {
    test('most recently used pose is first, with no duplicates', () async {
      await repository.markPoseUsed('a');
      await repository.markPoseUsed('b');
      await repository.markPoseUsed('a');
      expect(repository.recentPoseIds(), ['a', 'b']);
    });

    test('is capped at the configured maximum', () async {
      for (var i = 0; i < AppConstants.maxRecentPoses + 5; i++) {
        await repository.markPoseUsed('pose_$i');
      }
      expect(repository.recentPoseIds().length, AppConstants.maxRecentPoses);
    });
  });

  group('custom categories', () {
    test('added categories persist and are not duplicated', () async {
      await repository.addCustomCategory(
        const PoseCategory(id: 'studio', title: 'Studio', isCustom: true),
      );
      await repository.addCustomCategory(
        const PoseCategory(id: 'studio', title: 'Studio', isCustom: true),
      );
      expect(
        repository.customCategories().where((c) => c.id == 'studio').length,
        1,
      );
    });
  });

  group('custom pose import/update/delete', () {
    test(
      'importing copies the file into app storage and persists metadata',
      () async {
        final sourceFile = File(p.join(tempDir.path, 'source.jpg'))
          ..writeAsBytesSync([1, 2, 3, 4]);

        final pose = await repository.importCustomPose(
          sourceFilePath: sourceFile.path,
          title: 'My Pose',
          categoryId: kUncategorizedCategoryId,
          tags: const ['casual'],
        );

        expect(pose.title, 'My Pose');
        expect(File(pose.imagePath).existsSync(), isTrue);
        expect(pose.imagePath, isNot(sourceFile.path));
        expect(repository.customPoses().map((p) => p.id), contains(pose.id));
        expect(repository.isCustomPoseFileMissing(pose), isFalse);
      },
    );

    test('updating changes title/category without touching the file', () async {
      final sourceFile = File(p.join(tempDir.path, 'source2.jpg'))
        ..writeAsBytesSync([1, 2, 3]);
      final pose = await repository.importCustomPose(
        sourceFilePath: sourceFile.path,
        title: 'Old Name',
        categoryId: kUncategorizedCategoryId,
      );

      await repository.updateCustomPose(
        pose.copyWith(title: 'New Name', categoryId: 'standing'),
      );

      final updated = repository.customPoses().firstWhere(
        (p) => p.id == pose.id,
      );
      expect(updated.title, 'New Name');
      expect(updated.categoryId, 'standing');
      expect(File(updated.imagePath).existsSync(), isTrue);
    });

    test(
      'deleting removes the record, its copied file, and any favorite flag',
      () async {
        final sourceFile = File(p.join(tempDir.path, 'source3.jpg'))
          ..writeAsBytesSync([1, 2, 3]);
        final pose = await repository.importCustomPose(
          sourceFilePath: sourceFile.path,
          title: 'To Delete',
          categoryId: kUncategorizedCategoryId,
        );
        await repository.setFavorite(pose.id, true);

        await repository.deleteCustomPose(pose.id);

        expect(repository.customPoses().where((p) => p.id == pose.id), isEmpty);
        expect(File(pose.imagePath).existsSync(), isFalse);
        expect(repository.favoriteIds().contains(pose.id), isFalse);
        // The original source file the user picked is never touched.
        expect(sourceFile.existsSync(), isTrue);
      },
    );
  });
}
