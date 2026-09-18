import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Compact "1.0x" style pill shown while zoom changes, similar to native
/// camera apps. Callers control visibility/fade timing.
class ZoomIndicator extends StatelessWidget {
  const ZoomIndicator({super.key, required this.zoom});

  final double zoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cameraControlSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${zoom.toStringAsFixed(zoom < 10 ? 1 : 0)}x',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
