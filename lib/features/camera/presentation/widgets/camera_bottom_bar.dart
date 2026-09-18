import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import 'shutter_button.dart';

class CameraBottomBar extends StatelessWidget {
  const CameraBottomBar({
    super.key,
    required this.onCapture,
    required this.isCapturing,
    required this.hapticsEnabled,
    required this.onOpenGallery,
    required this.latestThumbnailPath,
    required this.onFlipCamera,
    required this.canFlipCamera,
    required this.isSwitchingCamera,
  });

  final VoidCallback onCapture;
  final bool isCapturing;
  final bool hapticsEnabled;
  final VoidCallback onOpenGallery;
  final String? latestThumbnailPath;
  final VoidCallback onFlipCamera;
  final bool canFlipCamera;
  final bool isSwitchingCamera;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GalleryThumbnail(path: latestThumbnailPath, onTap: onOpenGallery),
          ShutterButton(
            onPressed: onCapture,
            isBusy: isCapturing,
            hapticsEnabled: hapticsEnabled,
          ),
          _FlipCameraButton(
            onTap: onFlipCamera,
            enabled: canFlipCamera,
            isBusy: isSwitchingCamera,
          ),
        ],
      ),
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.path, required this.onTap});

  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    return Semantics(
      button: true,
      label: 'Open recent captures',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white54, width: 1.5),
            color: AppColors.cameraControlSurface,
            image: file != null && file.existsSync()
                ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                : null,
          ),
          child: file == null
              ? const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                  size: 22,
                )
              : null,
        ),
      ),
    );
  }
}

class _FlipCameraButton extends StatelessWidget {
  const _FlipCameraButton({
    required this.onTap,
    required this.enabled,
    required this.isBusy,
  });

  final VoidCallback onTap;
  final bool enabled;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Switch camera',
      enabled: enabled,
      child: Material(
        color: AppColors.cameraControlSurface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: AnimatedRotation(
              turns: isBusy ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.cameraswitch_outlined,
                color: enabled ? Colors.white : Colors.white30,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
