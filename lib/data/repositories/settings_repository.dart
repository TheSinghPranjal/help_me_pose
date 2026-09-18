import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/app_settings.dart';
import '../../services/storage/local_storage_service.dart';

class SettingsRepository {
  SettingsRepository(this._storage);

  final LocalStorageService _storage;

  bool isOnboardingComplete() =>
      _storage.getBool(AppConstants.prefsOnboardingComplete);

  Future<void> setOnboardingComplete(bool value) =>
      _storage.setBool(AppConstants.prefsOnboardingComplete, value);

  AppSettings load() {
    final themeIndex = _storage.getString(AppConstants.prefsThemeMode);
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeIndex,
      orElse: () => ThemeMode.system,
    );
    return AppSettings(
      themeMode: themeMode,
      defaultOverlayOpacity: _storage.getDouble(
        AppConstants.prefsDefaultOverlayOpacity,
        defaultValue: AppConstants.defaultOverlayOpacity,
      ),
      mirrorFrontCamera: _storage.getBool(AppConstants.prefsMirrorFrontCamera),
      hapticFeedbackEnabled: _storage.getBool(
        AppConstants.prefsHapticFeedback,
        defaultValue: true,
      ),
      autoSaveAfterCapture: _storage.getBool(
        AppConstants.prefsAutoSaveAfterCapture,
        defaultValue: true,
      ),
    );
  }

  Future<void> save(AppSettings settings) async {
    await _storage.setString(
      AppConstants.prefsThemeMode,
      settings.themeMode.name,
    );
    await _storage.setDouble(
      AppConstants.prefsDefaultOverlayOpacity,
      settings.defaultOverlayOpacity,
    );
    await _storage.setBool(
      AppConstants.prefsMirrorFrontCamera,
      settings.mirrorFrontCamera,
    );
    await _storage.setBool(
      AppConstants.prefsHapticFeedback,
      settings.hapticFeedbackEnabled,
    );
    await _storage.setBool(
      AppConstants.prefsAutoSaveAfterCapture,
      settings.autoSaveAfterCapture,
    );
  }
}
