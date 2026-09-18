import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_me_pose/core/providers/core_providers.dart';
import 'package:help_me_pose/features/camera/state/overlay_notifier.dart';
import 'package:help_me_pose/services/storage/local_storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'help_me_pose_overlay_test_',
    );
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.create();
    container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
  });

  tearDown(() async {
    container.dispose();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('defaults to the configured default overlay opacity (10%)', () {
    final settings = container.read(overlaySettingsProvider);
    expect(settings.opacity, closeTo(0.10, 0.0001));
  });

  test('setOpacity clamps to [0, 1]', () {
    final notifier = container.read(overlaySettingsProvider.notifier);
    notifier.setOpacity(1.5);
    expect(container.read(overlaySettingsProvider).opacity, 1.0);
    notifier.setOpacity(-0.5);
    expect(container.read(overlaySettingsProvider).opacity, 0.0);
  });

  test('setScale clamps within the configured min/max range', () {
    final notifier = container.read(overlaySettingsProvider.notifier);
    notifier.setScale(100);
    final clampedHigh = container.read(overlaySettingsProvider).scale;
    expect(clampedHigh, lessThan(100));
    notifier.setScale(-5);
    final clampedLow = container.read(overlaySettingsProvider).scale;
    expect(clampedLow, greaterThan(0));
  });

  test(
    'translateBy accumulates offset, and reset returns to centered/default state',
    () {
      final notifier = container.read(overlaySettingsProvider.notifier);
      notifier.translateBy(const Offset(10, 20));
      notifier.translateBy(const Offset(5, -5));
      expect(
        container.read(overlaySettingsProvider).offset,
        const Offset(15, 15),
      );

      notifier.setAdjustMode(true);
      notifier.reset();
      final reset = container.read(overlaySettingsProvider);
      expect(reset.offset, Offset.zero);
      expect(reset.scale, 1.0);
      expect(reset.isAdjustMode, isFalse);
      expect(reset.opacity, closeTo(0.10, 0.0001));
    },
  );
}
