import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'wikipedia_language';
  static const String _appLanguageKey = 'app_language';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme Mode
  ThemeMode get themeMode {
    final themeString = _prefs.getString(_themeKey) ?? 'system';
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    await _prefs.setString(_themeKey, themeString);
  }

  // Wikipedia Language
  String get wikipediaLanguage {
    return _prefs.getString(_languageKey) ?? 'en';
  }

  Future<void> setWikipediaLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  // App Language
  String get appLanguage {
    return _prefs.getString(_appLanguageKey) ?? 'en';
  }

  Future<void> setAppLanguage(String language) async {
    await _prefs.setString(_appLanguageKey, language);
  }

  // Supported Wikipedia languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'vi': 'Tiếng Việt',
    'fr': 'Français',
    'ja': '日本語',
    'de': 'Deutsch',
    'es': 'Español',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ko': '한국어',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'th': 'ไทย',
    'nl': 'Nederlands',
    'sv': 'Svenska',
    'no': 'Norsk',
    'da': 'Dansk',
    'fi': 'Suomi',
    'pl': 'Polski',
  };

  // App UI Languages (for interface)
  static const Map<String, String> appLanguages = {
    'en': 'English',
    'vi': 'Tiếng Việt',
    'fr': 'Français',
    'ja': '日本語',
  };
}
