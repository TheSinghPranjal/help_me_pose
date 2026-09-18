import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:help_me_pose/core/error/app_exceptions.dart';
import 'package:help_me_pose/data/repositories/capture_repository.dart';
import 'package:help_me_pose/domain/models/filter_option.dart';
import 'package:help_me_pose/services/filters/photo_filter_service.dart';
import 'package:help_me_pose/services/media/media_save_service.dart';
import 'package:help_me_pose/services/permissions/permission_service.dart';
import 'package:help_me_pose/services/storage/local_storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_path_provider.dart';

class _MockPhotoFilterService extends Mock implements PhotoFilterService {}

class _MockMediaSaveService extends Mock implements MediaSaveService {}

class _MockPermissionService extends Mock implements PermissionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _MockPhotoFilterService filterService;
  late _MockMediaSaveService mediaSaveService;
  late _MockPermissionService permissionService;
  late CaptureRepository repository;

  final rawBytes = Uint8List.fromList([1, 2, 3]);
  final processedBytes = Uint8List.fromList([4, 5, 6]);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(PhotoFilterType.original);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'help_me_pose_capture_test_',
    );
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.create();

    filterService = _MockPhotoFilterService();
    mediaSaveService = _MockMediaSaveService();
    permissionService = _MockPermissionService();
    repository = CaptureRepository(
      storage,
      filterService,
      mediaSaveService,
      permissionService,
    );

    when(
      () => permissionService.checkSavePhotoPermission(),
    ).thenAnswer((_) async => AppPermissionStatus.granted);
    when(
      () => filterService.apply(any(), any()),
    ).thenAnswer((_) async => processedBytes);
    when(
      () => mediaSaveService.saveImage(any(), filename: any(named: 'filename')),
    ).thenAnswer(
      (_) async =>
          AssetEntity(id: 'asset_1', typeInt: 1, width: 1080, height: 1920),
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test(
    'finalizeAndSave applies the filter, saves to the gallery, and records the capture',
    () async {
      final photo = await repository.finalizeAndSave(
        rawBytes,
        filter: PhotoFilterType.vivid,
        poseIdUsed: 'pose_1',
      );

      verify(
        () => filterService.apply(rawBytes, PhotoFilterType.vivid),
      ).called(1);
      verify(
        () => mediaSaveService.saveImage(
          processedBytes,
          filename: any(named: 'filename'),
        ),
      ).called(1);

      expect(photo.galleryAssetId, 'asset_1');
      expect(photo.poseIdUsed, 'pose_1');
      expect(photo.width, 1080);
      expect(File(photo.filePath).readAsBytesSync(), processedBytes);
      expect(repository.recentCaptures().map((c) => c.id), contains(photo.id));
    },
  );

  test(
    'throws PhotoPermissionDeniedException and saves nothing when permission is refused',
    () async {
      when(
        () => permissionService.checkSavePhotoPermission(),
      ).thenAnswer((_) async => AppPermissionStatus.denied);
      when(
        () => permissionService.requestSavePhotoPermission(),
      ).thenAnswer((_) async => AppPermissionStatus.denied);

      await expectLater(
        repository.finalizeAndSave(rawBytes, filter: PhotoFilterType.original),
        throwsA(isA<PhotoPermissionDeniedException>()),
      );

      verifyNever(
        () =>
            mediaSaveService.saveImage(any(), filename: any(named: 'filename')),
      );
      expect(repository.recentCaptures(), isEmpty);
    },
  );

  test(
    'recentCapturesVerified drops entries whose cached file was deleted externally',
    () async {
      final photo = await repository.finalizeAndSave(
        rawBytes,
        filter: PhotoFilterType.original,
      );
      expect(repository.recentCaptures(), hasLength(1));

      File(photo.filePath).deleteSync();

      final verified = await repository.recentCapturesVerified();
      expect(verified, isEmpty);
      expect(repository.recentCaptures(), isEmpty);
    },
  );
}
