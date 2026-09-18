import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/pose.dart';
import '../../../../shared/widgets/pose_thumbnail.dart';
import '../../application/pose_providers.dart';
import '../../../camera/state/overlay_notifier.dart';
import 'edit_custom_pose_screen.dart';

class PoseDetailScreen extends ConsumerWidget {
  const PoseDetailScreen({super.key, required this.pose});

  final Pose pose;

  void _useThisPose(BuildContext context, WidgetRef ref) {
    ref.read(activePoseProvider.notifier).select(pose);
    ref.read(overlaySettingsProvider.notifier).reset();
    ref.read(homeTabIndexProvider.notifier).state = 0;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this pose?'),
        content: const Text(
          'This removes it from My Poses. The original photo on your device (if any) will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(customPosesProvider.notifier).delete(pose.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritePoseIdsProvider);
    final isFavorite = favorites.contains(pose.id);
    final missingFile = ref.watch(poseFileMissingProvider(pose));

    return Scaffold(
      appBar: AppBar(
        title: Text(pose.title),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            color: isFavorite ? Colors.redAccent : null,
            onPressed: () =>
                ref.read(favoritePoseIdsProvider.notifier).toggle(pose.id),
          ),
          if (pose.isCustom)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditCustomPoseScreen(pose: pose),
                    ),
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context, ref);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Rename / edit category'),
                ),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: missingFile
                    ? const _MissingFileNotice()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: PoseThumbnail(pose: pose, fit: BoxFit.contain),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pose.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in pose.tags)
                          Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    pose.attribution,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: missingFile
                      ? null
                      : () => _useThisPose(context, ref),
                  child: const Text('Use This Pose'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingFileNotice extends StatelessWidget {
  const _MissingFileNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('This pose\'s image is no longer available.'),
        ],
      ),
    );
  }
}
