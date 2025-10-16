import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;
  String _currentText = '';

  bool get isPlaying => _isPlaying;
  String get currentText => _currentText;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _currentText = '';
      });

      _flutterTts.setErrorHandler((msg) {
        if (kDebugMode) {
          print('TTS Error: $msg');
        }
        _isPlaying = false;
      });

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('TTS Initialization Error: $e');
      }
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    if (_isPlaying) {
      await stop();
    }

    _currentText = text;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
    _currentText = '';
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    await _flutterTts.speak(_currentText);
  }

  Future<void> setLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  Future<List<dynamic>> getLanguages() async {
    return await _flutterTts.getLanguages;
  }

  void dispose() {
    _flutterTts.stop();
  }
}
