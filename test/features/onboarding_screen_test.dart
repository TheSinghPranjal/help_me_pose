import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_me_pose/core/providers/core_providers.dart';
import 'package:help_me_pose/features/onboarding/application/onboarding_notifier.dart';
import 'package:help_me_pose/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:help_me_pose/services/storage/local_storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'help_me_pose_onboarding_test_',
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

  Widget buildApp() {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: OnboardingScreen()),
    );
  }

  testWidgets('shows the first onboarding step with a Skip action', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Pick a pose to guide you'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(container.read(onboardingCompleteProvider), isFalse);
  });

  testWidgets('tapping Skip marks onboarding as complete', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(container.read(onboardingCompleteProvider), isTrue);
  });

  testWidgets(
    'paging through to the last step changes the button label to Get started',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Capture the real shot'), findsOneWidget);
    },
  );
}
