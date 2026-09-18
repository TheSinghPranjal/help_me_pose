import 'dart:ui' show Offset;

import 'package:camera/camera.dart';

/// Thin abstraction over the `camera` plugin so screens/notifiers never call
/// the plugin's static/global APIs directly. Owns the single active
/// [CameraController] for the app (still image capture only — no recording
/// APIs are ever invoked).
class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  Future<List<CameraDescription>> availableCameraList() => availableCameras();

  Future<CameraController> open(
    CameraDescription description, {
    ResolutionPreset resolutionPreset = ResolutionPreset.veryHigh,
  }) async {
    await disposeController();
    final controller = CameraController(
      description,
      resolutionPreset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    await controller.initialize();
    return controller;
  }

  Future<void> disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<({double min, double max})> zoomRange() async {
    final controller = _requireController();
    final min = await controller.getMinZoomLevel();
    final max = await controller.getMaxZoomLevel();
    return (min: min, max: max);
  }

  Future<void> setZoom(double zoom) async {
    final controller = _requireController();
    await controller.setZoomLevel(zoom);
  }

  Future<void> setFlashMode(FlashMode mode) async {
    final controller = _requireController();
    await controller.setFlashMode(mode);
  }

  Future<void> setFocusAndExposurePoint(Offset normalizedPoint) async {
    final controller = _requireController();
    await controller.setFocusPoint(normalizedPoint);
    await controller.setExposurePoint(normalizedPoint);
  }

  Future<XFile> takePicture() async {
    final controller = _requireController();
    return controller.takePicture();
  }

  CameraController _requireController() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera controller is not initialized.');
    }
    return controller;
  }
}
