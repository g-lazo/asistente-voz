import 'package:flutter_tts/flutter_tts.dart';

abstract class VoiceOutput {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Speaks with the platform voice, preferring Spanish.
///
/// The language is chosen once the engine has listed its languages. Chrome
/// loads its voices lazily, so the first list it gives can be empty; an empty
/// list (or a failed request) therefore means "not ready yet" and the choice
/// is tried again at the next [speak]. Any non-empty list settles it for good.
/// The constructor already asks once, so the voices are loading before the
/// first reply.
class TtsVoiceOutput implements VoiceOutput {
  final _tts = FlutterTts();
  bool _settled = false;
  Future<void>? _attempt;

  TtsVoiceOutput() {
    _ensureLanguage();
  }

  /// Runs at most one attempt at a time; callers during one wait for it.
  Future<void> _ensureLanguage() {
    if (_settled) return Future.value();
    return _attempt ??= _chooseLanguage().whenComplete(() => _attempt = null);
  }

  /// Latin American Spanish first, then Spain's; the default voice otherwise.
  Future<void> _chooseLanguage() async {
    try {
      final languages = [
        for (final l in await _tts.getLanguages as List) l.toString(),
      ];
      if (languages.isEmpty) return;
      _settled = true;
      for (final wanted in const ['es_mx', 'es_us', 'es_es']) {
        for (final l in languages) {
          if (l.replaceAll('-', '_').toLowerCase() == wanted) {
            await _tts.setLanguage(l);
            return;
          }
        }
      }
    } catch (_) {
      // Keep the default voice; an unsettled choice is tried again.
    }
  }

  @override
  Future<void> speak(String text) async {
    await _ensureLanguage();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
