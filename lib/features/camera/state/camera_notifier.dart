import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../domain/models/camera_state.dart';

final cameraNotifierProvider = NotifierProvider<CameraNotifier, CameraState>(
  CameraNotifier.new,
);

/// Owns the [CameraController] lifecycle and exposes an immutable
/// [CameraState] snapshot for the UI. Still-photo capture only — no video
/// recording API is ever called from here.
class CameraNotifier extends Notifier<CameraState> {
  late final _service = ref.read(cameraServiceProvider);

  CameraController? get controller => _service.controller;

  @override
  CameraState build() {
    ref.onDispose(() {
      _service.disposeController();
    });
    return const CameraState();
  }

  Future<void> initialize() async {
    if (state.status == CameraStatus.initializing) return;
    state = state.copyWith(status: CameraStatus.initializing, clearError: true);
    try {
      final cameras = await _service.availableCameraList();
      if (cameras.isEmpty) {
        state = state.copyWith(
          status: CameraStatus.unavailable,
          errorMessage: 'No camera was found on this device.',
        );
        return;
      }
      final rearIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      await _openCamera(cameras, rearIndex >= 0 ? rearIndex : 0);
    } on CameraException catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: _describeException(e),
      );
    } catch (_) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Could not start the camera.',
      );
    }
  }

  Future<void> _openCamera(List<CameraDescription> cameras, int index) async {
    await _service.open(cameras[index]);
    var minZoom = AppConstants.minCameraZoom;
    var maxZoom = AppConstants.minCameraZoom;
    try {
      final range = await _service.zoomRange();
      minZoom = range.min;
      maxZoom = range.max;
    } catch (_) {
      // Some devices/emulators do not report a zoom range; fall back to 1x.
    }
    state = state.copyWith(
      status: CameraStatus.ready,
      cameras: cameras,
      activeCameraIndex: index,
      minZoom: minZoom,
      maxZoom: maxZoom,
      zoom: minZoom,
      flashMode: FlashMode.off,
      supportsFlash: true,
      clearError: true,
    );
  }

  Future<void> switchCamera() async {
    if (!state.hasMultipleCameras || state.isSwitchingCamera) return;
    state = state.copyWith(isSwitchingCamera: true);
    try {
      final nextIndex = (state.activeCameraIndex + 1) % state.cameras.length;
      await _openCamera(state.cameras, nextIndex);
    } on CameraException catch (e) {
      state = state.copyWith(errorMessage: _describeException(e));
    } finally {
      state = state.copyWith(isSwitchingCamera: false);
    }
  }

  Future<void> setZoom(double zoom) async {
    if (!state.isReady) return;
    final clamped = zoom.clamp(state.minZoom, state.maxZoom);
    if ((clamped - state.zoom).abs() < 0.001) return;
    state = state.copyWith(zoom: clamped);
    try {
      await _service.setZoom(clamped);
    } catch (_) {
      // Ignore transient zoom failures (e.g. mid camera-switch).
    }
  }

  Future<void> cycleFlashMode() async {
    if (!state.isReady || !state.supportsFlash) return;
    const order = [FlashMode.off, FlashMode.auto, FlashMode.always];
    final next = order[(order.indexOf(state.flashMode) + 1) % order.length];
    try {
      await _service.setFlashMode(next);
      state = state.copyWith(flashMode: next);
    } on CameraException {
      state = state.copyWith(supportsFlash: false);
    }
  }

  Future<void> focusAndExposeAt(Offset normalizedPoint) async {
    if (!state.isReady) return;
    try {
      await _service.setFocusAndExposurePoint(normalizedPoint);
    } catch (_) {
      // Tap-to-focus is a nice-to-have; ignore devices that don't support it.
    }
  }

  Future<XFile?> capturePhoto() async {
    if (!state.isReady || state.isCapturing) return null;
    state = state.copyWith(isCapturing: true);
    try {
      return await _service.takePicture();
    } on CameraException catch (e) {
      state = state.copyWith(errorMessage: _describeException(e));
      return null;
    } finally {
      state = state.copyWith(isCapturing: false);
    }
  }

  Future<void> pauseForBackground() async {
    try {
      await controller?.pausePreview();
    } catch (_) {}
  }

  Future<void> resumeFromBackground() async {
    try {
      await controller?.resumePreview();
    } catch (_) {}
  }

  Future<void> disposeCamera() => _service.disposeController();

  String _describeException(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Camera access is not available.';
      default:
        return e.description ?? 'Something went wrong with the camera.';
    }
  }
}
