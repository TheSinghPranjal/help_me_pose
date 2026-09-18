import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_me_pose/domain/models/camera_state.dart';

const _back = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);
const _front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

void main() {
  group('CameraState', () {
    test('initial state has no cameras and is not ready', () {
      const state = CameraState();
      expect(state.isReady, isFalse);
      expect(state.activeCamera, isNull);
      expect(state.hasMultipleCameras, isFalse);
    });

    test('reports the active camera and lens direction', () {
      final state = CameraState(
        status: CameraStatus.ready,
        cameras: const [_back, _front],
        activeCameraIndex: 0,
      );
      expect(state.isReady, isTrue);
      expect(state.activeCamera, _back);
      expect(state.isFrontCamera, isFalse);
      expect(state.hasMultipleCameras, isTrue);
    });

    test('switching the active index flips isFrontCamera', () {
      final state = CameraState(
        status: CameraStatus.ready,
        cameras: const [_back, _front],
        activeCameraIndex: 0,
      );
      final switched = state.copyWith(activeCameraIndex: 1);
      expect(switched.isFrontCamera, isTrue);
    });

    test('copyWith(clearError: true) clears a previous error message', () {
      const state = CameraState(
        status: CameraStatus.error,
        errorMessage: 'boom',
      );
      final cleared = state.copyWith(
        status: CameraStatus.initializing,
        clearError: true,
      );
      expect(cleared.errorMessage, isNull);
    });

    test('a capture-in-flight flag prevents treating the camera as idle', () {
      final state = CameraState(
        status: CameraStatus.ready,
        cameras: const [_back],
        isCapturing: true,
      );
      expect(state.isCapturing, isTrue);
      expect(state.isReady, isTrue);
    });
  });
}
