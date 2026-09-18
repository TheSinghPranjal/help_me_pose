import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.onOpenSettings,
    required this.flashMode,
    required this.supportsFlash,
    required this.onCycleFlash,
    required this.isAdjustMode,
    required this.hasActivePose,
    required this.onToggleAdjustMode,
  });

  final VoidCallback onOpenSettings;
  final FlashMode flashMode;
  final bool supportsFlash;
  final VoidCallback onCycleFlash;
  final bool isAdjustMode;
  final bool hasActivePose;
  final VoidCallback onToggleAdjustMode;

  IconData get _flashIcon => switch (flashMode) {
    FlashMode.off => Icons.flash_off_rounded,
    FlashMode.auto => Icons.flash_auto_rounded,
    FlashMode.always || FlashMode.torch => Icons.flash_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.settings_outlined,
            semanticLabel: 'Settings',
            onTap: onOpenSettings,
          ),
          const Spacer(),
          if (hasActivePose)
            _CircleIconButton(
              icon: isAdjustMode
                  ? Icons.check_rounded
                  : Icons.open_with_rounded,
              semanticLabel: isAdjustMode
                  ? 'Done adjusting pose'
                  : 'Adjust pose position',
              onTap: onToggleAdjustMode,
              highlighted: isAdjustMode,
            ),
          if (hasActivePose) const SizedBox(width: AppSpacing.sm),
          if (supportsFlash)
            _CircleIconButton(
              icon: _flashIcon,
              semanticLabel: 'Flash mode',
              onTap: onCycleFlash,
            ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: highlighted ? AppColors.accent : AppColors.cameraControlSurface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: highlighted ? Colors.black : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
