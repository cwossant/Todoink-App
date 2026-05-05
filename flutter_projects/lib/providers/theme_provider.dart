import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hive_service.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier()
  : super(HiveService.getSavedThemeMode() ?? ThemeMode.light);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await HiveService.saveThemeMode(mode);
  }
}

/// Provider for theme mode (system/light/dark), persisted in Hive prefs.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Soft, comfy sage green color for the app
const Color appPrimaryGreen = Color(0xFF9CAF88);

/// Provider for primary theme color
final primaryColorProvider = StateProvider<Color>((ref) {
  return appPrimaryGreen;
});

/// Notifier class for managing theme color selection
class PrimaryColorNotifier extends StateNotifier<Color> {
  PrimaryColorNotifier() : super(appPrimaryGreen);

  void setColor(Color color) {
    state = color;
  }

  void reset() {
    state = appPrimaryGreen;
  }
}

/// Provider for primary color with custom notifier
final customPrimaryColorProvider =
    StateNotifierProvider<PrimaryColorNotifier, Color>((ref) {
  return PrimaryColorNotifier();
});
