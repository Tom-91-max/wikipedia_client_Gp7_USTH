// lib/common/providers/language_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../network/api_client.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  final SettingsService _settingsService = SettingsService();
  final ApiClient _apiClient = ApiClient();

  Future<void> _loadLanguage() async {
    try {
      await _settingsService.init();
      final saved = _settingsService.wikipediaLanguage;
      state = saved;
      await _apiClient.updateLanguage(saved);
    } catch (_) {
      state = 'en';
      await _apiClient.updateLanguage('en');
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _settingsService.setWikipediaLanguage(language);
      await _apiClient.updateLanguage(language);
      state = language;
    } catch (_) {}
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
