import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  final _settingsService = SettingsService();

  Future<void> _loadTheme() async {
    await _settingsService.init();
    state = _settingsService.themeMode;
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _settingsService.setThemeMode(mode);
    state = mode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
