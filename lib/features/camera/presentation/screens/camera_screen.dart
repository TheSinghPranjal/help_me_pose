import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/camera_state.dart';
import '../../../../services/permissions/permission_service.dart';
import '../../../../shared/widgets/permission_request_view.dart';
import '../../../gallery/application/gallery_providers.dart';
import '../../../poses/application/pose_providers.dart';
import '../../../settings/application/settings_notifier.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../state/camera_notifier.dart';
import '../../state/camera_permission_notifier.dart';
import '../../state/overlay_notifier.dart';
import '../widgets/camera_bottom_bar.dart';
import '../widgets/camera_preview_layer.dart';
import '../widgets/camera_top_bar.dart';
import '../widgets/pose_control_panel.dart';
import '../widgets/pose_overlay_layer.dart';
import '../widgets/zoom_indicator.dart';
import 'capture_review_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver, RouteAware {
  bool _cameraInitRequested = false;
  bool _showZoomIndicator = false;
  Timer? _zoomIndicatorTimer;
  double _gestureBaselineZoom = 1;
  double _gestureBaselineOverlayScale = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _zoomIndicatorTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(cameraPermissionProvider.notifier).refresh();
      ref.read(cameraNotifierProvider.notifier).resumeFromBackground();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ref.read(cameraNotifierProvider.notifier).pauseForBackground();
    }
  }

  @override
  void didPushNext() =>
      ref.read(cameraNotifierProvider.notifier).pauseForBackground();

  @override
  void didPopNext() {
    // Only resume if the Camera tab is actually the visible one — a pushed
    // screen (e.g. Settings) may have been opened from a different tab.
    if (ref.read(homeTabIndexProvider) == 0) {
      ref.read(cameraNotifierProvider.notifier).resumeFromBackground();
    }
  }

  void _maybeInitializeCamera(AppPermissionStatus status) {
    if (status != AppPermissionStatus.granted || _cameraInitRequested) return;
    _cameraInitRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraNotifierProvider.notifier).initialize();
    });
  }

  void _flashZoomIndicator() {
    setState(() => _showZoomIndicator = true);
    _zoomIndicatorTimer?.cancel();
    _zoomIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showZoomIndicator = false);
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureBaselineZoom = ref.read(cameraNotifierProvider).zoom;
    _gestureBaselineOverlayScale = ref.read(overlaySettingsProvider).scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final overlay = ref.read(overlaySettingsProvider);
    if (overlay.isAdjustMode) {
      ref
          .read(overlaySettingsProvider.notifier)
          .setScale(_gestureBaselineOverlayScale * details.scale);
      ref
          .read(overlaySettingsProvider.notifier)
          .translateBy(details.focalPointDelta);
    } else {
      if ((details.scale - 1.0).abs() > 0.005) {
        ref
            .read(cameraNotifierProvider.notifier)
            .setZoom(_gestureBaselineZoom * details.scale);
        _flashZoomIndicator();
      }
    }
  }

  Future<void> _handleCapture() async {
    final xfile = await ref
        .read(cameraNotifierProvider.notifier)
        .capturePhoto();
    if (xfile == null || !mounted) return;
    final bytes = await xfile.readAsBytes();
    final activePose = ref.read(activePoseProvider);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CaptureReviewScreen(
          rawJpegBytes: bytes,
          poseIdUsed: activePose?.id,
        ),
      ),
    );
  }

  void _openSettings() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

  void _openGallery() => ref.read(homeTabIndexProvider.notifier).state = 2;

  void _openPoseLibrary() => ref.read(homeTabIndexProvider.notifier).state = 1;

  @override
  Widget build(BuildContext context) {
    final permissionAsync = ref.watch(cameraPermissionProvider);

    return Scaffold(
      backgroundColor: AppColors.cameraBackdrop,
      body: SafeArea(
        child: permissionAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (err, _) => _CameraErrorView(
            message: 'Something went wrong while checking camera permission.',
            onRetry: () => ref.invalidate(cameraPermissionProvider),
          ),
          data: (status) {
            _maybeInitializeCamera(status);
            return switch (status) {
              AppPermissionStatus.granted => _CameraBody(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                showZoomIndicator: _showZoomIndicator,
                onOpenSettings: _openSettings,
                onOpenGallery: _openGallery,
                onOpenPoseLibrary: _openPoseLibrary,
                onCapture: _handleCapture,
              ),
              AppPermissionStatus.permanentlyDenied => PermissionRequestView(
                icon: Icons.camera_alt_outlined,
                title: 'Camera access is off',
                message:
                    'Help me Pose needs your camera to show a live preview and take photos. '
                    'Enable camera access in Settings to continue.',
                primaryActionLabel: 'Open Settings',
                onPrimaryAction: () =>
                    ref.read(permissionServiceProvider).openSettings(),
              ),
              AppPermissionStatus.restricted => const PermissionRequestView(
                icon: Icons.block_outlined,
                title: 'Camera is restricted',
                message:
                    'Camera access is restricted on this device and cannot be enabled here.',
                primaryActionLabel: 'OK',
                onPrimaryAction: _noOp,
              ),
              _ => PermissionRequestView(
                icon: Icons.camera_alt_outlined,
                title: 'Allow camera access',
                message:
                    'Help me Pose uses your camera to show a live preview so you can line up your shot.',
                primaryActionLabel: 'Allow Camera Access',
                onPrimaryAction: () =>
                    ref.read(cameraPermissionProvider.notifier).request(),
              ),
            };
          },
        ),
      ),
    );
  }
}

void _noOp() {}

// Split into a separate widget (rather than inline in the switch above) so
// only this subtree rebuilds as camera/overlay state changes, not the
// permission-gating logic in the parent.
class _CameraBody extends ConsumerWidget {
  const _CameraBody({
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.showZoomIndicator,
    required this.onOpenSettings,
    required this.onOpenGallery,
    required this.onOpenPoseLibrary,
    required this.onCapture,
  });

  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final bool showZoomIndicator;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPoseLibrary;
  final Future<void> Function() onCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cameraNotifierProvider.select((s) => s.status));

    if (status == CameraStatus.error || status == CameraStatus.unavailable) {
      final message =
          ref.watch(cameraNotifierProvider.select((s) => s.errorMessage)) ??
          'Camera unavailable.';
      return _CameraErrorView(
        message: message,
        onRetry: () => ref.read(cameraNotifierProvider.notifier).initialize(),
      );
    }

    if (status != CameraStatus.ready) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _PreviewConsumer(),
          const _OverlayConsumer(),
          Column(
            children: [
              _TopBarConsumer(onOpenSettings: onOpenSettings),
              const Spacer(),
              if (showZoomIndicator)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ZoomConsumer(),
                  ),
                ),
              const SizedBox(height: 12),
              _PoseControlConsumer(onOpenPoseLibrary: onOpenPoseLibrary),
              const SizedBox(height: 8),
              _BottomBarConsumer(
                onOpenGallery: onOpenGallery,
                onCapture: onCapture,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewConsumer extends ConsumerWidget {
  const _PreviewConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cameraNotifierProvider.notifier);
    // Rebuild whenever the active camera changes (a new CameraController is
    // created on every switch) — not just when front/back facing flips.
    ref.watch(cameraNotifierProvider.select((s) => s.activeCameraIndex));
    final isFrontCamera = ref.watch(
      cameraNotifierProvider.select((s) => s.isFrontCamera),
    );
    final controller = notifier.controller;
    if (controller == null) return const SizedBox.shrink();
    return CameraPreviewLayer(
      controller: controller,
      isFrontCamera: isFrontCamera,
      onTapToFocus: (point) => notifier.focusAndExposeAt(point),
    );
  }
}

class _OverlayConsumer extends ConsumerWidget {
  const _OverlayConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pose = ref.watch(activePoseProvider);
    if (pose == null) return const SizedBox.shrink();
    final overlaySettings = ref.watch(overlaySettingsProvider);
    return PoseOverlayLayer(pose: pose, settings: overlaySettings);
  }
}

class _TopBarConsumer extends ConsumerWidget {
  const _TopBarConsumer({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashMode = ref.watch(
      cameraNotifierProvider.select((s) => s.flashMode),
    );
    final supportsFlash = ref.watch(
      cameraNotifierProvider.select((s) => s.supportsFlash),
    );
    final hasActivePose = ref.watch(activePoseProvider) != null;
    final isAdjustMode = ref.watch(
      overlaySettingsProvider.select((s) => s.isAdjustMode),
    );
    return CameraTopBar(
      onOpenSettings: onOpenSettings,
      flashMode: flashMode,
      supportsFlash: supportsFlash,
      onCycleFlash: () =>
          ref.read(cameraNotifierProvider.notifier).cycleFlashMode(),
      isAdjustMode: isAdjustMode,
      hasActivePose: hasActivePose,
      onToggleAdjustMode: () => ref
          .read(overlaySettingsProvider.notifier)
          .setAdjustMode(!isAdjustMode),
    );
  }
}

class _ZoomConsumer extends ConsumerWidget {
  const _ZoomConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(cameraNotifierProvider.select((s) => s.zoom));
    return ZoomIndicator(zoom: zoom);
  }
}

class _PoseControlConsumer extends ConsumerWidget {
  const _PoseControlConsumer({required this.onOpenPoseLibrary});

  final VoidCallback onOpenPoseLibrary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pose = ref.watch(activePoseProvider);
    final overlaySettings = ref.watch(overlaySettingsProvider);
    return PoseControlPanel(
      activePose: pose,
      overlaySettings: overlaySettings,
      onChoosePose: onOpenPoseLibrary,
      onOpacityChanged: (v) =>
          ref.read(overlaySettingsProvider.notifier).setOpacity(v),
      onReset: () => ref.read(overlaySettingsProvider.notifier).reset(),
      onClear: () {
        ref.read(activePoseProvider.notifier).clear();
        ref.read(overlaySettingsProvider.notifier).reset();
      },
    );
  }
}

class _BottomBarConsumer extends ConsumerWidget {
  const _BottomBarConsumer({
    required this.onOpenGallery,
    required this.onCapture,
  });

  final VoidCallback onOpenGallery;
  final Future<void> Function() onCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCapturing = ref.watch(
      cameraNotifierProvider.select((s) => s.isCapturing),
    );
    final isSwitching = ref.watch(
      cameraNotifierProvider.select((s) => s.isSwitchingCamera),
    );
    final canFlip = ref.watch(
      cameraNotifierProvider.select((s) => s.hasMultipleCameras),
    );
    final hapticsEnabled = ref.watch(
      settingsNotifierProvider.select((s) => s.hapticFeedbackEnabled),
    );
    final recentCaptures = ref.watch(recentCapturesProvider);
    final latestThumbnail = recentCaptures.isEmpty
        ? null
        : recentCaptures.first.filePath;

    return CameraBottomBar(
      onCapture: () {
        if (!isCapturing) onCapture();
      },
      isCapturing: isCapturing,
      hapticsEnabled: hapticsEnabled,
      onOpenGallery: onOpenGallery,
      latestThumbnailPath: latestThumbnail,
      onFlipCamera: () =>
          ref.read(cameraNotifierProvider.notifier).switchCamera(),
      canFlipCamera: canFlip,
      isSwitchingCamera: isSwitching,
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PermissionRequestView(
      icon: Icons.error_outline_rounded,
      title: 'Camera unavailable',
      message: message,
      primaryActionLabel: 'Try Again',
      onPrimaryAction: onRetry,
    );
  }
}
