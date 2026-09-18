import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/pose.dart';

/// Renders a [Pose] thumbnail, transparently handling the two backing
/// formats (bundled SVG silhouettes vs. imported raster photos) and a
/// friendly fallback when a custom pose's source file has been removed.
class PoseThumbnail extends StatelessWidget {
  const PoseThumbnail({
    super.key,
    required this.pose,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final Pose pose;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;

    Widget child;
    if (pose.isSvg) {
      child = ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(
            pose.imagePath,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              isDark ? Colors.white70 : Colors.black87,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    } else {
      final path = pose.thumbnailPath ?? pose.imagePath;
      final file = File(path);
      if (!file.existsSync()) {
        child = _MissingFile(background: background);
      } else {
        child = Image.file(
          file,
          fit: fit,
          errorBuilder: (context, error, stack) =>
              _MissingFile(background: background),
        );
      }
    }

    if (borderRadius == null) return ClipRect(child: child);
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class _MissingFile extends StatelessWidget {
  const _MissingFile({required this.background});

  final Color background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.error,
          size: 28,
        ),
      ),
    );
  }
}
