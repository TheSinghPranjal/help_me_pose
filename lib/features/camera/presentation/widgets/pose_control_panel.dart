import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/overlay_settings.dart';
import '../../../../domain/models/pose.dart';
import '../../../../shared/widgets/pose_thumbnail.dart';

/// The camera screen's pose-related control surface: a subtle "Choose a
/// pose" prompt when nothing is selected, or the active pose chip with an
/// opacity slider, reset, and clear controls once one is.
class PoseControlPanel extends StatelessWidget {
  const PoseControlPanel({
    super.key,
    required this.activePose,
    required this.overlaySettings,
    required this.onChoosePose,
    required this.onOpacityChanged,
    required this.onReset,
    required this.onClear,
  });

  final Pose? activePose;
  final OverlaySettings overlaySettings;
  final VoidCallback onChoosePose;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onReset;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (activePose == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: AppColors.cameraControlSurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onChoosePose,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Choose a pose',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final pose = activePose!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.cameraControlSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 40,
                height: 40,
                child: PoseThumbnail(pose: pose),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pose.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(overlaySettings.opacity * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: overlaySettings.opacity,
                      min: 0,
                      max: 1,
                      activeColor: AppColors.accent,
                      inactiveColor: Colors.white24,
                      onChanged: onOpacityChanged,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Reset overlay',
              onPressed: onReset,
              icon: const Icon(
                Icons.restart_alt_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Remove pose',
              onPressed: onClear,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
