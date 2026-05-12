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

class GreenThemeOption {
  final String label;
  final Color color;

  const GreenThemeOption(this.label, this.color);
}

/// Green-based theme options (current + 5 more)
const List<GreenThemeOption> greenThemeOptions = [
  GreenThemeOption('Sage', appPrimaryGreen),
  GreenThemeOption('Emerald', Color(0xFF2E7D32)),
  GreenThemeOption('Mint', Color(0xFF66BB6A)),
  GreenThemeOption('Forest', Color(0xFF1B5E20)),
  GreenThemeOption('Teal Green', Color(0xFF00897B)),
  GreenThemeOption('Lime', Color(0xFF9CCC65)),
];

/// Provider for primary theme color
final primaryColorProvider = StateProvider<Color>((ref) {
  return appPrimaryGreen;
});

/// Notifier class for managing theme color selection
class PrimaryColorNotifier extends StateNotifier<Color> {
  PrimaryColorNotifier() : super(_initialColor());

  static Color _initialColor() {
    final saved = HiveService.getSavedPrimaryColorValue();
    if (saved == null) return appPrimaryGreen;
    return Color(saved);
  }

  Future<void> setColor(Color color) async {
    state = color;
    await HiveService.savePrimaryColorValue(color.toARGB32());
  }

  Future<void> reset() async {
    state = appPrimaryGreen;
    await HiveService.savePrimaryColorValue(appPrimaryGreen.toARGB32());
  }
}

/// Provider for primary color with custom notifier
final customPrimaryColorProvider =
    StateNotifierProvider<PrimaryColorNotifier, Color>((ref) {
  return PrimaryColorNotifier();
});
