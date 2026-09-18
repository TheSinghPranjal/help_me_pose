import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/camera/presentation/screens/camera_screen.dart';
import '../../features/camera/state/camera_notifier.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/poses/presentation/screens/pose_library_screen.dart';
import '../providers/navigation_providers.dart';

/// Root navigation shell. The camera tab is kept mounted at all times (an
/// [IndexedStack] index, not a pushed route) so its [CameraController]
/// survives switching tabs instantly with no re-initialization — but the
/// live preview stream is explicitly paused while another tab is showing,
/// and resumed when the Camera tab becomes visible again, to avoid wasting
/// battery/CPU on a preview nobody can see.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  Widget build(BuildContext context) {
    ref.listen<int>(homeTabIndexProvider, (previous, next) {
      final cameraNotifier = ref.read(cameraNotifierProvider.notifier);
      if (next == 0) {
        cameraNotifier.resumeFromBackground();
      } else if (previous == 0) {
        cameraNotifier.pauseForBackground();
      }
    });

    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [CameraScreen(), PoseLibraryScreen(), GalleryScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Poses',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
        ],
      ),
    );
  }
}
