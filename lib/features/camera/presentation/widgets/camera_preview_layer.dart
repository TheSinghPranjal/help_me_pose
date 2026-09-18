import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'focus_ring.dart';

/// Fills the available space with the live camera preview while preserving
/// its native aspect ratio (cropping overflow rather than stretching), and
/// exposes tap-to-focus.
///
/// Mirroring note: the *preview* is mirrored horizontally for the front
/// camera (so movement feels natural, like a mirror) but the pose overlay
/// drawn above it is never mirrored, and the saved photo is only mirrored
/// if the user explicitly enables "Mirror Selfie" in Settings.
class CameraPreviewLayer extends StatefulWidget {
  const CameraPreviewLayer({
    super.key,
    required this.controller,
    required this.isFrontCamera,
    required this.onTapToFocus,
  });

  final CameraController controller;
  final bool isFrontCamera;
  final ValueChanged<Offset> onTapToFocus;

  @override
  State<CameraPreviewLayer> createState() => _CameraPreviewLayerState();
}

class _CameraPreviewLayerState extends State<CameraPreviewLayer> {
  Offset? _focusPoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final previewAspectRatio = widget.controller.value.aspectRatio;
        var scale = size.aspectRatio * previewAspectRatio;
        if (scale < 1) scale = 1 / scale;

        return ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = details.localPosition;
              final normalized = Offset(
                (local.dx / box.size.width).clamp(0.0, 1.0),
                (local.dy / box.size.height).clamp(0.0, 1.0),
              );
              widget.onTapToFocus(normalized);
              setState(() => _focusPoint = local);
            },
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: previewAspectRatio,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: widget.isFrontCamera
                            ? (Matrix4.identity()..rotateY(math.pi))
                            : Matrix4.identity(),
                        child: CameraPreview(widget.controller),
                      ),
                    ),
                  ),
                ),
                if (_focusPoint != null)
                  FocusRing(
                    center: _focusPoint!,
                    onCompleted: () => setState(() => _focusPoint = null),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
