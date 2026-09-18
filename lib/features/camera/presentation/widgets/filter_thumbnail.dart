import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/filter_preview_matrices.dart';
import '../../../../domain/models/filter_option.dart';

/// A single filter choice in the capture review filter strip. Uses a fast
/// GPU [ColorFilter] for the live preview rather than re-encoding the image
/// per filter — the authoritative pixel-level filter is only computed once,
/// when the user taps Save.
class FilterThumbnail extends StatelessWidget {
  const FilterThumbnail({
    super.key,
    required this.option,
    required this.previewBytes,
    required this.isSelected,
    required this.onTap,
  });

  final FilterOption option;
  final Uint8List previewBytes;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ColorFiltered(
              colorFilter: FilterPreviewMatrices.forType(option.type),
              child: Image.memory(
                previewBytes,
                fit: BoxFit.cover,
                cacheWidth: 120,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.label,
            style: TextStyle(
              color: isSelected ? AppColors.accent : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
