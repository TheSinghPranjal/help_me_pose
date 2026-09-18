import 'package:camera/camera.dart';

/// High-level lifecycle status of the camera controller.
enum CameraStatus {
  initial,
  initializing,
  ready,
  error,
  permissionDenied,
  unavailable,
}

/// Immutable snapshot of everything the camera screen needs to render,
/// independent of the overlay/pose state.
class CameraState {
  const CameraState({
    this.status = CameraStatus.initial,
    this.cameras = const [],
    this.activeCameraIndex = 0,
    this.flashMode = FlashMode.off,
    this.minZoom = 1.0,
    this.maxZoom = 1.0,
    this.zoom = 1.0,
    this.isCapturing = false,
    this.isSwitchingCamera = false,
    this.errorMessage,
    this.supportsFlash = true,
  });

  final CameraStatus status;
  final List<CameraDescription> cameras;
  final int activeCameraIndex;
  final FlashMode flashMode;
  final double minZoom;
  final double maxZoom;
  final double zoom;
  final bool isCapturing;
  final bool isSwitchingCamera;
  final String? errorMessage;
  final bool supportsFlash;

  CameraDescription? get activeCamera =>
      cameras.isEmpty || activeCameraIndex >= cameras.length
      ? null
      : cameras[activeCameraIndex];

  bool get isFrontCamera =>
      activeCamera?.lensDirection == CameraLensDirection.front;
  bool get hasMultipleCameras => cameras.length > 1;
  bool get isReady => status == CameraStatus.ready;

  CameraState copyWith({
    CameraStatus? status,
    List<CameraDescription>? cameras,
    int? activeCameraIndex,
    FlashMode? flashMode,
    double? minZoom,
    double? maxZoom,
    double? zoom,
    bool? isCapturing,
    bool? isSwitchingCamera,
    String? errorMessage,
    bool clearError = false,
    bool? supportsFlash,
  }) {
    return CameraState(
      status: status ?? this.status,
      cameras: cameras ?? this.cameras,
      activeCameraIndex: activeCameraIndex ?? this.activeCameraIndex,
      flashMode: flashMode ?? this.flashMode,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      zoom: zoom ?? this.zoom,
      isCapturing: isCapturing ?? this.isCapturing,
      isSwitchingCamera: isSwitchingCamera ?? this.isSwitchingCamera,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      supportsFlash: supportsFlash ?? this.supportsFlash,
    );
  }
}
