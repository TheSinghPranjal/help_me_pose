import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'services/storage/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The camera experience is designed and tested for portrait use; locking
  // orientation keeps controls and the overlay layout predictable while the
  // capture pipeline still relies on sensor/EXIF orientation, not this lock,
  // to produce correctly-oriented photos.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storage = await LocalStorageService.create();

  runApp(
    ProviderScope(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      child: const HelpMePoseApp(),
    ),
  );
}
