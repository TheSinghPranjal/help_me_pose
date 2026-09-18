import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../domain/models/captured_photo.dart';
import '../../../domain/models/filter_option.dart';

final recentCapturesProvider =
    NotifierProvider<RecentCapturesNotifier, List<CapturedPhoto>>(
      RecentCapturesNotifier.new,
    );

class RecentCapturesNotifier extends Notifier<List<CapturedPhoto>> {
  @override
  List<CapturedPhoto> build() =>
      ref.read(captureRepositoryProvider).recentCaptures();

  Future<void> refresh() async {
    state = await ref.read(captureRepositoryProvider).recentCapturesVerified();
  }

  Future<CapturedPhoto> save(
    Uint8List rawJpegBytes, {
    required PhotoFilterType filter,
    String? poseIdUsed,
  }) async {
    final photo = await ref
        .read(captureRepositoryProvider)
        .finalizeAndSave(rawJpegBytes, filter: filter, poseIdUsed: poseIdUsed);
    state = [photo, ...state];
    return photo;
  }
}
