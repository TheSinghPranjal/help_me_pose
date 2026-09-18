import 'package:flutter/material.dart';

import '../../../../domain/models/overlay_settings.dart';
import '../../../../domain/models/pose.dart';
import '../../../../shared/widgets/pose_overlay_image.dart';

/// Purely presentational alignment-guide layer drawn above the camera
/// preview. This widget is never part of the capture pipeline — capturing a
/// photo reads frames directly from the [CameraController], so whatever is
/// rendered here can never end up baked into the saved photograph.
class PoseOverlayLayer extends StatelessWidget {
  const PoseOverlayLayer({
    super.key,
    required this.pose,
    required this.settings,
  });

  final Pose pose;
  final OverlaySettings settings;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: settings.opacity,
        child: Transform.translate(
          offset: settings.offset,
          child: Transform.scale(
            scale: settings.scale,
            child: FractionallySizedBox(
              widthFactor: 0.86,
              heightFactor: 0.86,
              child: PoseOverlayImage(pose: pose),
            ),
          ),
        ),
      ),
    );
  }
}
