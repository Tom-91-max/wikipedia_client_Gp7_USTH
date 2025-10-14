import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tts_service.dart';

class TTSNotifier extends StateNotifier<bool> {
  TTSNotifier() : super(false) {
    _initTTS();
  }

  final _ttsService = TTSService();

  Future<void> _initTTS() async {
    await _ttsService.init();
  }

  Future<void> speak(String text) async {
    await _ttsService.speak(text);
    state = _ttsService.isPlaying;
  }

  Future<void> stop() async {
    await _ttsService.stop();
    state = false;
  }

  Future<void> pause() async {
    await _ttsService.pause();
    state = false;
  }

  bool get isPlaying => _ttsService.isPlaying;
}

final ttsProvider = StateNotifierProvider<TTSNotifier, bool>((ref) {
  return TTSNotifier();
});
