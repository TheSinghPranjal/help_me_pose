import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Redirects all `path_provider` lookups to a single directory the test
/// controls, so repository code that reads/writes files under the app's
/// documents directory can be exercised without a real device.
class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;

  @override
  Future<String?> getApplicationCachePath() async => path;
}
