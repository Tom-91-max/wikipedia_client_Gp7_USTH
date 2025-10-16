import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../network/api_client.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  final _settingsService = SettingsService();
  final _apiClient = ApiClient();

  Future<void> _loadLanguage() async {
    await _settingsService.init();
    state = _settingsService.wikipediaLanguage;
  }

  Future<void> setLanguage(String language) async {
    await _settingsService.setWikipediaLanguage(language);
    _apiClient.updateLanguage(language);
    state = language;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
