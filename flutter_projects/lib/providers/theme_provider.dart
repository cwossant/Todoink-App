import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for theme mode (light/dark)
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
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
