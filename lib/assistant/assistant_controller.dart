import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../tasks/task.dart';
import '../tasks/task_repository.dart';
import 'command_parser.dart';
import 'replies.dart';
import 'speech_input.dart';
import 'voice_output.dart';

enum MicState { idle, listening, cancelArmed, busy }

class ChatMessage {
  const ChatMessage(this.text, {required this.fromUser});

  final String text;
  final bool fromUser;
}

const _cancelDistance = -80.0;
const _cancelledHintTime = Duration(milliseconds: 1500);

class AssistantController extends ChangeNotifier {
  AssistantController({
    required this._speech,
    required this._voice,
    required TaskRepository tasks,
    required this._muted,
    this._now = DateTime.now,
  }) : _tasks = tasks {
    _subscription = tasks.watch().listen(
      (list) => _pending = pendingCount(list),
      onError: (Object _) {},
    );
    _muted.addListener(_onMutedChanged);
  }

  final SpeechInput _speech;
  final VoiceOutput _voice;
  final TaskRepository _tasks;
  final ValueListenable<bool> _muted;
  final DateTime Function() _now;
  late final StreamSubscription<List<Task>> _subscription;

  final _messages = <ChatMessage>[const ChatMessage(greeting, fromUser: false)];
  MicState _state = MicState.idle;
  String _partial = '';
  int _pending = 0;
  bool _disposed = false;

  // True from the press until the recognizer is listening, so a second press
  // is ignored and a quick release is not lost.
  bool _starting = false;
  bool _releasedWhileStarting = false;

  // The running speech.cancel(), so a new press never starts the recognizer
  // underneath it.
  Future<void>? _cancelling;

  bool _cancelledShown = false;
  Timer? _cancelledTimer;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  MicState get state => _state;
  String get partial => _partial;

  String get hint => switch (_state) {
    MicState.idle =>
      _cancelledShown ? 'Cancelado' : 'Mantén presionado para hablar',
    MicState.listening =>
      'Suelta para enviar · desliza a la izquierda para cancelar',
    MicState.cancelArmed => 'Suelta para cancelar',
    MicState.busy => 'Guardando...',
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _setState(MicState state) {
    _state = state;
    _notify();
  }

  void _clearCancelledHint() {
    _cancelledTimer?.cancel();
    _cancelledTimer = null;
    _cancelledShown = false;
  }

  Future<void> pressStart() async {
    if (_state != MicState.idle || _starting) return;
    _starting = true;
    _releasedWhileStarting = false;
    _clearCancelledHint();
    try {
      try {
        await _voice.stop();
      } catch (_) {}
      final cancelling = _cancelling;
      if (cancelling != null) await cancelling;
      if (_disposed) return;

      SpeechStatus status;
      try {
        status = await _speech.prepare();
      } catch (_) {
        status = SpeechStatus.unavailable;
      }
      if (_disposed) return;
      if (status != SpeechStatus.ready) {
        _say(
          status == SpeechStatus.permissionDenied
              ? replyMicDenied
              : replySpeechUnavailable,
        );
        return;
      }

      _partial = '';
      try {
        await _speech.start((text) {
          if (_state != MicState.listening && _state != MicState.cancelArmed) {
            return;
          }
          _partial = text;
          _notify();
        });
      } catch (_) {
        if (_disposed) return;
        _say(replySpeechUnavailable);
        return;
      }
      if (_disposed) {
        _cancelSpeech();
        return;
      }
      _setState(MicState.listening);
    } finally {
      _starting = false;
    }
    if (_releasedWhileStarting && _state == MicState.listening) {
      await pressEnd();
    }
  }

  /// [dx] is the horizontal distance from where the press started.
  void dragUpdate(double dx) {
    if (_state == MicState.listening && dx <= _cancelDistance) {
      _setState(MicState.cancelArmed);
    } else if (_state == MicState.cancelArmed && dx > _cancelDistance) {
      _setState(MicState.listening);
    }
  }

  Future<void> pressEnd() async {
    if (_starting) {
      _releasedWhileStarting = true;
      return;
    }
    if (_state == MicState.cancelArmed) {
      await _cancel();
    } else if (_state == MicState.listening) {
      await _send();
    }
  }

  Future<void> _cancel() async {
    _partial = '';
    _cancelledShown = true;
    _cancelledTimer = Timer(_cancelledHintTime, () {
      _cancelledShown = false;
      _notify();
    });
    _setState(MicState.idle);
    final cancelling = _cancelling = _cancelSpeech();
    await cancelling;
    if (identical(_cancelling, cancelling)) _cancelling = null;
  }

  /// Errors from the recognizer are ignored; a failing cancel has no remedy.
  Future<void> _cancelSpeech() =>
      Future.sync(_speech.cancel).catchError((Object _) {});

  void _onMutedChanged() {
    if (_muted.value) {
      Future.sync(_voice.stop).catchError((Object _) {});
    }
  }

  Future<void> _send() async {
    _setState(MicState.busy);
    String heard;
    try {
      heard = (await _speech.stop()).trim();
    } catch (_) {
      heard = '';
    }
    if (_disposed) return;
    _partial = '';

    if (heard.isEmpty) {
      _say(replyNotUnderstood);
      _setState(MicState.idle);
      return;
    }
    _messages.add(ChatMessage(heard, fromUser: true));
    _notify();

    final task = parseCommand(heard, _now());
    if (task == null) {
      _say(replyNotUnderstood);
    } else {
      final before = _pending;
      try {
        await _tasks.add(task);
        if (_disposed) return;
        // The list may arrive after add completes; the new task counts anyway.
        _say(replySaved(task, max(_pending, before + 1)));
      } catch (_) {
        if (_disposed) return;
        _say(replySaveFailed);
      }
    }
    _setState(MicState.idle);
  }

  /// Shows the reply and reads it aloud unless muted.
  void _say(String text) {
    _messages.add(ChatMessage(text, fromUser: false));
    _notify();
    if (!_muted.value) {
      // The bubble is already on screen, so a failing voice is ignored.
      unawaited(
        Future.sync(() => _voice.speak(spokenText(text)))
            .catchError((Object _) {}),
      );
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _muted.removeListener(_onMutedChanged);
    if (_state == MicState.listening || _state == MicState.cancelArmed) {
      _cancelSpeech();
    }
    _cancelledTimer?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}
