import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/filter_preview_matrices.dart';
import '../../../../domain/models/captured_photo.dart';
import '../../../../domain/models/filter_option.dart';
import '../../../../shared/widgets/permission_request_view.dart';
import '../../../gallery/application/gallery_providers.dart';
import '../../../settings/application/settings_notifier.dart';
import '../widgets/filter_thumbnail.dart';

/// Shown immediately after every capture. The reference overlay is never
/// part of [rawJpegBytes] — it is drawn in a separate widget layer on the
/// camera screen and is not read by the camera plugin's capture pipeline.
class CaptureReviewScreen extends ConsumerStatefulWidget {
  const CaptureReviewScreen({
    super.key,
    required this.rawJpegBytes,
    this.poseIdUsed,
  });

  final Uint8List rawJpegBytes;
  final String? poseIdUsed;

  @override
  ConsumerState<CaptureReviewScreen> createState() =>
      _CaptureReviewScreenState();
}

class _CaptureReviewScreenState extends ConsumerState<CaptureReviewScreen> {
  PhotoFilterType _selectedFilter = PhotoFilterType.original;
  final Map<PhotoFilterType, CapturedPhoto> _savedByFilter = {};
  bool _isSaving = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    final autoSave = ref.read(settingsNotifierProvider).autoSaveAfterCapture;
    if (autoSave) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _save());
    }
  }

  Future<void> _save() async {
    if (_isSaving || _savedByFilter.containsKey(_selectedFilter)) return;
    setState(() {
      _isSaving = true;
      _permissionDenied = false;
    });
    try {
      final photo = await ref
          .read(recentCapturesProvider.notifier)
          .save(
            widget.rawJpegBytes,
            filter: _selectedFilter,
            poseIdUsed: widget.poseIdUsed,
          );
      if (!mounted) return;
      setState(() => _savedByFilter[_selectedFilter] = photo);
      HapticFeedback.lightImpact();
    } on PhotoPermissionDeniedException {
      if (mounted) setState(() => _permissionDenied = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the photo. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _selectFilter(PhotoFilterType type) {
    if (type == _selectedFilter) return;
    setState(() => _selectedFilter = type);
  }

  Future<void> _share() async {
    final photo = _savedByFilter[_selectedFilter];
    if (photo == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(photo.filePath)]));
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: AppColors.cameraBackdrop,
        body: SafeArea(
          child: PermissionRequestView(
            icon: Icons.photo_library_outlined,
            title: 'Photo access needed',
            message:
                'Help me Pose needs permission to save this photo to your gallery.',
            primaryActionLabel: 'Open Settings',
            onPrimaryAction: () =>
                ref.read(permissionServiceProvider).openSettings(),
          ),
        ),
      );
    }

    final hasSavedCurrent = _savedByFilter.containsKey(_selectedFilter);
    final saveLabel = hasSavedCurrent
        ? 'Saved'
        : (_selectedFilter == PhotoFilterType.original
              ? 'Save'
              : 'Save Filtered Copy');

    return Scaffold(
      backgroundColor: AppColors.cameraBackdrop,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Retake',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: hasSavedCurrent ? _share : null,
                    tooltip: 'Share',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: ColorFiltered(
                    colorFilter: FilterPreviewMatrices.forType(_selectedFilter),
                    child: Image.memory(
                      widget.rawJpegBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  for (final option in FilterOption.all) ...[
                    FilterThumbnail(
                      option: option,
                      previewBytes: widget.rawJpegBytes,
                      isSelected: _selectedFilter == option.type,
                      onTap: () => _selectFilter(option.type),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasSavedCurrent || _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(saveLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
