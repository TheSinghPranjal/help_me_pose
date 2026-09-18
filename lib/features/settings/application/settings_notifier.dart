import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../domain/models/app_settings.dart';

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.read(settingsRepositoryProvider).load();
  }

  Future<void> _update(AppSettings Function(AppSettings) transform) async {
    final next = transform(state);
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setDefaultOverlayOpacity(double value) =>
      _update((s) => s.copyWith(defaultOverlayOpacity: value));

  Future<void> setMirrorFrontCamera(bool value) =>
      _update((s) => s.copyWith(mirrorFrontCamera: value));

  Future<void> setHapticFeedbackEnabled(bool value) =>
      _update((s) => s.copyWith(hapticFeedbackEnabled: value));

  Future<void> setAutoSaveAfterCapture(bool value) =>
      _update((s) => s.copyWith(autoSaveAfterCapture: value));
}
