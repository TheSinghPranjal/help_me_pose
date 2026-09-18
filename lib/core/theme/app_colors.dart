import 'package:flutter/material.dart';

/// Centralized color palette for Help me Pose.
///
/// The camera experience is optimized for a dark, distraction-free surface
/// regardless of the active [ThemeMode], since controls must never compete
/// visually with the live preview.
abstract final class AppColors {
  static const Color accent = Color(0xFFE8A34C);
  static const Color accentMuted = Color(0xFFC98A3B);

  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0EFEC);
  static const Color lightOnBackground = Color(0xFF17171B);
  static const Color lightOnSurfaceMuted = Color(0xFF6C6C74);
  static const Color lightBorder = Color(0xFFE4E3DF);

  static const Color darkBackground = Color(0xFF0B0B0D);
  static const Color darkSurface = Color(0xFF141416);
  static const Color darkSurfaceVariant = Color(0xFF1C1C1F);
  static const Color darkOnBackground = Color(0xFFF4F4F2);
  static const Color darkOnSurfaceMuted = Color(0xFF9A9AA1);
  static const Color darkBorder = Color(0xFF2A2A2E);

  static const Color error = Color(0xFFE05B5B);
  static const Color success = Color(0xFF4CAF7D);

  /// Camera surface is always near-black, independent of app theme.
  static const Color cameraBackdrop = Color(0xFF000000);
  static const Color cameraScrim = Color(0x99000000);
  static const Color cameraControlSurface = Color(0x59000000);
  static const Color cameraOnControl = Color(0xFFFFFFFF);
}
