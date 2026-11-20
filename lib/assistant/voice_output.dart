import 'package:flutter_tts/flutter_tts.dart';

abstract class VoiceOutput {
  Future<void> speak(String text);
  Future<void> stop();
}

class TtsVoiceOutput implements VoiceOutput {
  final _tts = FlutterTts();
  Future<void>? _ready;

  /// Latin American Spanish first, then Spain's; the default voice otherwise.
  Future<void> _chooseLanguage() async {
    try {
      final languages = [
        for (final l in await _tts.getLanguages as List) l.toString(),
      ];
      for (final wanted in const ['es_mx', 'es_us', 'es_es']) {
        for (final l in languages) {
          if (l.replaceAll('-', '_').toLowerCase() == wanted) {
            await _tts.setLanguage(l);
            return;
          }
        }
      }
    } catch (_) {
      // Keep the default voice.
    }
  }

  @override
  Future<void> speak(String text) async {
    await (_ready ??= _chooseLanguage());
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
