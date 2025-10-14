import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

class AppLanguageNotifier extends StateNotifier<Locale> {
  AppLanguageNotifier() : super(const Locale('en')) {
    _loadLanguage();
  }

  final _settingsService = SettingsService();

  Future<void> _loadLanguage() async {
    await _settingsService.init();
    final languageCode = _settingsService.appLanguage;
    state = Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    await _settingsService.setAppLanguage(languageCode);
    state = Locale(languageCode);
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, Locale>((ref) {
  return AppLanguageNotifier();
});
