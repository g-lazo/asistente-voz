import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechStatus { ready, permissionDenied, unavailable }

abstract class SpeechInput {
  /// Asks for the microphone permission the first time.
  Future<SpeechStatus> prepare();

  /// [onText] receives everything heard since this call.
  Future<void> start(void Function(String text) onText);

  /// Everything heard, '' if nothing.
  Future<String> stop();

  Future<void> cancel();
}

final _whitespace = RegExp(r'\s+');

/// Joins what the recognizer reports across restarts of its session: finished
/// segments plus the one still being spoken.
class TranscriptAccumulator {
  final _finished = <String>[];
  String _current = '';

  /// [segment] is the recognizer's text for the current session only.
  void update(String segment, {required bool isFinal}) {
    segment = segment.trim().replaceAll(_whitespace, ' ');
    if (isFinal) {
      if (segment.isNotEmpty) _finished.add(segment);
      _current = '';
    } else {
      _current = segment;
    }
  }

  String get text =>
      [..._finished, _current].where((s) => s.isNotEmpty).join(' ');

  void reset() {
    _finished.clear();
    _current = '';
  }
}

String _normalizeLocale(String id) => id.replaceAll('-', '_').toLowerCase();

/// The locale to ask the recognizer for, out of the ids it lists.
/// First es_MX, then es_US, then any Spanish locale, compared without regard
/// to case or to `-` versus `_`; the id is returned exactly as listed.
/// When no Spanish locale is listed: 'es-MX' on web, where the plugin cannot
/// list locales and the browser would otherwise listen in the page language;
/// null (the system default) elsewhere.
String? pickSpeechLocale(List<String> localeIds, {required bool web}) {
  for (final wanted in const ['es_mx', 'es_us']) {
    for (final id in localeIds) {
      if (_normalizeLocale(id) == wanted) return id;
    }
  }
  for (final id in localeIds) {
    if (_normalizeLocale(id).startsWith('es')) return id;
  }
  return web ? 'es-MX' : null;
}

class SttSpeechInput implements SpeechInput {
  final _stt = SpeechToText();
  final _transcript = TranscriptAccumulator();
  String? _localeId;
  bool _localeResolved = false;
  bool _holding = false;
  void Function(String text)? _onText;
  Completer<void>? _finalResult;

  // The last result of the running session, to keep it if the session ends
  // without a final one.
  String _lastSegment = '';
  bool _lastWasFinal = true;

  @override
  Future<SpeechStatus> prepare() async {
    try {
      final ok = await _stt.initialize(onStatus: _onStatus);
      if (!ok) {
        return await _stt.hasPermission
            ? SpeechStatus.unavailable
            : SpeechStatus.permissionDenied;
      }
      if (!_localeResolved) {
        final locales = await _stt.locales();
        _localeId = pickSpeechLocale(
          [for (final l in locales) l.localeId],
          web: kIsWeb,
        );
        _localeResolved = true;
      }
      return SpeechStatus.ready;
    } catch (_) {
      return SpeechStatus.unavailable;
    }
  }

  @override
  Future<void> start(void Function(String text) onText) async {
    _transcript.reset();
    _lastSegment = '';
    _lastWasFinal = true;
    _onText = onText;
    _holding = true;
    try {
      await _listen();
    } catch (_) {
      _holding = false;
      rethrow;
    }
  }

  Future<void> _listen() => _stt.listen(
    onResult: _onResult,
    listenOptions: SpeechListenOptions(
      partialResults: true,
      localeId: _localeId,
    ),
  );

  void _onResult(SpeechRecognitionResult result) {
    _lastSegment = result.recognizedWords;
    _lastWasFinal = result.finalResult;
    _transcript.update(result.recognizedWords, isFinal: result.finalResult);
    _onText?.call(_transcript.text);
    if (result.finalResult) {
      final waiting = _finalResult;
      if (waiting != null && !waiting.isCompleted) waiting.complete();
    }
  }

  /// The recognizer may end its session on a pause; keep listening while the
  /// button is held.
  void _onStatus(String status) {
    if (status != SpeechToText.doneStatus || !_holding) return;
    if (!_lastWasFinal) {
      _transcript.update(_lastSegment, isFinal: true);
      _lastWasFinal = true;
    }
    _listen().catchError((Object _) {});
  }

  @override
  Future<String> stop() async {
    _holding = false;
    final waiting = _finalResult = Completer<void>();
    try {
      await _stt.stop();
      await waiting.future.timeout(const Duration(seconds: 1));
    } catch (_) {
      // Timed out or the plugin failed: use what was heard so far.
    }
    _finalResult = null;
    return _transcript.text;
  }

  @override
  Future<void> cancel() async {
    _holding = false;
    _transcript.reset();
    try {
      await _stt.cancel();
    } catch (_) {}
  }
}
