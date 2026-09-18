import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/captured_photo.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../application/gallery_providers.dart';
import 'photo_viewer_screen.dart';

/// Photographs captured through Help me Pose, grouped by date. This is
/// distinct from the Pose Library — it only ever shows photos the user took,
/// never bundled or imported pose references.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captures = ref.watch(recentCapturesProvider);
    final grouped = _groupByDate(captures);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Captures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: captures.isEmpty
          ? const EmptyState(
              icon: Icons.photo_camera_back_outlined,
              title: 'No captures yet',
              message:
                  'Photos you take with Help me Pose will show up here, grouped by date.',
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(recentCapturesProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: grouped.length,
                itemBuilder: (context, sectionIndex) {
                  final section = grouped[sectionIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            section.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: AppSpacing.sm,
                                mainAxisSpacing: AppSpacing.sm,
                              ),
                          itemCount: section.photos.length,
                          itemBuilder: (context, i) {
                            final photo = section.photos[i];
                            return _CaptureThumbnail(photo: photo);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  List<_DateSection> _groupByDate(List<CapturedPhoto> photos) {
    final byDay = <DateTime, List<CapturedPhoto>>{};
    for (final photo in photos) {
      final day = DateTime(
        photo.capturedAt.year,
        photo.capturedAt.month,
        photo.capturedAt.day,
      );
      byDay.putIfAbsent(day, () => []).add(photo);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final yesterdayKey = todayKey.subtract(const Duration(days: 1));
    return days.map((day) {
      final label = day == todayKey
          ? 'Today'
          : day == yesterdayKey
          ? 'Yesterday'
          : DateFormat.yMMMMd().format(day);
      return _DateSection(label, byDay[day]!);
    }).toList();
  }
}

class _DateSection {
  _DateSection(this.label, this.photos);
  final String label;
  final List<CapturedPhoto> photos;
}

class _CaptureThumbnail extends StatelessWidget {
  const _CaptureThumbnail({required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final file = File(photo.filePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PhotoViewerScreen(photo: photo)),
        ),
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : const ColoredBox(
                color: Colors.black12,
                child: Icon(Icons.image_not_supported_outlined),
              ),
      ),
    );
  }
}
