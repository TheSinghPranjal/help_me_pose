import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/models/pose.dart';

/// Renders a [Pose] as an alignment-guide image, preserving its aspect
/// ratio (never stretched). Built-in vector silhouettes are tinted white so
/// they stay visible against any live camera background; imported photo
/// references are shown as-is.
class PoseOverlayImage extends StatelessWidget {
  const PoseOverlayImage({super.key, required this.pose});

  final Pose pose;

  @override
  Widget build(BuildContext context) {
    if (pose.isSvg) {
      return SvgPicture.asset(
        pose.imagePath,
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    }
    final file = File(pose.imagePath);
    if (!file.existsSync()) return const SizedBox.shrink();
    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
