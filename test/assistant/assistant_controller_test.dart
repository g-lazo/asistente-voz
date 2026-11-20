import 'dart:async';

import 'package:asistente_voz/assistant/assistant_controller.dart';
import 'package:asistente_voz/assistant/command_parser.dart';
import 'package:asistente_voz/assistant/replies.dart';
import 'package:asistente_voz/assistant/speech_input.dart';
import 'package:asistente_voz/assistant/voice_output.dart';
import 'package:asistente_voz/tasks/task.dart';
import 'package:asistente_voz/tasks/task_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSpeech implements SpeechInput {
  SpeechStatus status = SpeechStatus.ready;
  Object? startError;
  Completer<void>? cancelGate;
  String heard = '';
  int starts = 0;
  int cancelled = 0;
  void Function(String text)? _onText;
  final order = <String>[];

  void hear(String text) {
    heard = text;
    _onText!(text);
  }

  @override
  Future<SpeechStatus> prepare() async => status;

  @override
  Future<void> start(void Function(String text) onText) async {
    order.add('start');
    if (startError != null) throw startError!;
    starts++;
    _onText = onText;
  }

  @override
  Future<String> stop() async => heard;

  @override
  Future<void> cancel() async {
    cancelled++;
    if (cancelGate != null) await cancelGate!.future;
  }
}

class FakeVoice implements VoiceOutput {
  final spoken = <String>[];
  int stops = 0;
  Object? speakError;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    if (speakError != null) throw speakError!;
  }

  @override
  Future<void> stop() async => stops++;
}

/// `speak` is not async, so it fails synchronously.
class SyncThrowingVoice implements VoiceOutput {
  @override
  Future<void> speak(String text) => throw Exception('sync failure');

  @override
  Future<void> stop() => throw Exception('sync failure');
}

class FakeTasks implements TaskRepository {
  final added = <ParsedTask>[];
  bool emitOnAdd = true;

  void emit(List<Task> list) => _changes.add(list);
  Object? addError;
  Completer<void>? gate;
  // Synchronous so the new list reaches the controller before add completes,
  // like Firestore's local snapshot.
  final _changes = StreamController<List<Task>>.broadcast(sync: true);

  bool get hasListeners => _changes.hasListener;

  @override
  Stream<List<Task>> watch() => _changes.stream;

  @override
  Future<void> add(ParsedTask task) async {
    if (gate != null) await gate!.future;
    if (addError != null) throw addError!;
    added.add(task);
    if (!emitOnAdd) return;
    _changes.add([
      for (var i = 0; i < added.length; i++)
        Task(id: '$i', title: added[i].title, done: false, heard: ''),
    ]);
  }

  @override
  Future<void> setDone(String id, bool done) async {}

  @override
  Future<void> delete(String id) async {}
}

class Rig {
  Rig({DateTime? now, VoiceOutput? customVoice}) {
    controller = AssistantController(
      speech: speech,
      voice: customVoice ?? voice,
      tasks: tasks,
      muted: muted,
      now: () => now ?? DateTime(2026, 11, 19),
    );
  }

  final speech = FakeSpeech();
  final voice = FakeVoice();
  final tasks = FakeTasks();
  final muted = ValueNotifier<bool>(false);
  late final AssistantController controller;

  List<String> get texts => controller.messages.map((m) => m.text).toList();
}

Future<void> say(Rig r, String phrase) async {
  await r.controller.pressStart();
  r.speech.hear(phrase);
  await r.controller.pressEnd();
}

void main() {
  late Rig rig;

  setUp(() => rig = Rig());
  tearDown(() => rig.controller.dispose());

  test('starts with the greeting, idle', () {
    expect(rig.texts, [greeting]);
    expect(rig.controller.messages.single.fromUser, isFalse);
    expect(rig.controller.state, MicState.idle);
    expect(rig.controller.hint, 'Mantén presionado para hablar');
  });

  test('adds a task from a phrase', () async {
    await rig.controller.pressStart();
    expect(rig.controller.state, MicState.listening);
    expect(
      rig.controller.hint,
      'Suelta para enviar · desliza a la izquierda para cancelar',
    );
    rig.speech.hear('agrega comprar leche');
    expect(rig.controller.partial, 'agrega comprar leche');
    await rig.controller.pressEnd();

    expect(rig.texts, [
      greeting,
      'agrega comprar leche',
      'Listo, agregué "Comprar leche". Llevas 1 pendiente.',
    ]);
    expect(rig.controller.messages[1].fromUser, isTrue);
    expect(rig.tasks.added.single.title, 'Comprar leche');
    expect(rig.voice.spoken, [
      'Listo, agregué Comprar leche. Llevas 1 pendiente.',
    ]);
    expect(rig.controller.state, MicState.idle);
    expect(rig.controller.partial, '');
  });

  test('understands a date', () async {
    final r = Rig(now: DateTime(2026, 11, 19));
    addTearDown(r.controller.dispose);
    await say(r, 'recuérdame pagar el internet el viernes');
    expect(r.tasks.added.single.dueDate, DateTime(2026, 11, 20));
    expect(r.texts.last, contains('para el viernes 20 de noviembre'));
  });

  test('slide left cancels', () async {
    await rig.controller.pressStart();
    rig.speech.hear('agrega comprar leche');
    rig.controller.dragUpdate(-100);
    expect(rig.controller.state, MicState.cancelArmed);
    expect(rig.controller.hint, 'Suelta para cancelar');
    await rig.controller.pressEnd();

    expect(rig.tasks.added, isEmpty);
    expect(rig.controller.messages.length, 1);
    expect(rig.speech.cancelled, 1);
    expect(rig.controller.hint, 'Cancelado');
  });

  test('sliding back sends', () async {
    await rig.controller.pressStart();
    rig.speech.hear('agrega comprar leche');
    rig.controller.dragUpdate(-100);
    rig.controller.dragUpdate(-10);
    expect(rig.controller.state, MicState.listening);
    await rig.controller.pressEnd();
    expect(rig.tasks.added.length, 1);
  });

  test('empty press', () async {
    await say(rig, '');
    expect(rig.texts.last, replyNotUnderstood);
    expect(rig.controller.messages.length, 2);
    expect(rig.tasks.added, isEmpty);
  });

  test('trigger word alone', () async {
    await say(rig, 'agrega');
    expect(rig.texts.sublist(1), ['agrega', replyNotUnderstood]);
    expect(rig.tasks.added, isEmpty);
  });

  test('save failure', () async {
    rig.tasks.addError = Exception('offline');
    await say(rig, 'agrega comprar leche');
    expect(rig.texts.last, replySaveFailed);
    expect(rig.controller.state, MicState.idle);
  });

  test('muted', () async {
    rig.muted.value = true;
    await say(rig, 'agrega comprar leche');
    expect(rig.voice.spoken, isEmpty);
    expect(rig.texts.last, startsWith('Listo, agregué'));
  });

  test('stops talking before listening', () async {
    await rig.controller.pressStart();
    expect(rig.voice.stops, 1);
    expect(rig.speech.starts, 1);
    expect(rig.speech.order, ['start']);
  });

  test('permission denied', () async {
    rig.speech.status = SpeechStatus.permissionDenied;
    await rig.controller.pressStart();
    expect(rig.texts.last, replyMicDenied);
    expect(rig.controller.state, MicState.idle);
    expect(rig.speech.starts, 0);
  });

  test('recognition unavailable', () async {
    rig.speech.status = SpeechStatus.unavailable;
    await rig.controller.pressStart();
    expect(rig.texts.last, replySpeechUnavailable);
    expect(rig.controller.state, MicState.idle);
  });

  test('press while saving is ignored', () async {
    rig.tasks.gate = Completer<void>();
    await rig.controller.pressStart();
    rig.speech.hear('agrega comprar leche');
    final end = rig.controller.pressEnd();
    await Future<void>.delayed(Duration.zero);
    expect(rig.controller.state, MicState.busy);
    expect(rig.controller.hint, 'Guardando...');

    await rig.controller.pressStart();
    expect(rig.speech.starts, 1);

    rig.tasks.gate!.complete();
    await end;
    expect(rig.tasks.added.length, 1);
    expect(rig.controller.state, MicState.idle);
  });

  test('pressEnd while idle does nothing', () async {
    await rig.controller.pressEnd();
    expect(rig.controller.messages.length, 1);
    expect(rig.controller.state, MicState.idle);
  });

  test('a release during prepare still answers', () async {
    final start = rig.controller.pressStart();
    final end = rig.controller.pressEnd();
    await start;
    await end;
    expect(rig.texts.last, replyNotUnderstood);
    expect(rig.controller.state, MicState.idle);
  });

  test('a failing speech.start returns to idle', () async {
    rig.speech.startError = Exception('boom');
    await rig.controller.pressStart();
    expect(rig.controller.state, MicState.idle);
  });

  test('a failing voice.speak is ignored', () async {
    rig.voice.speakError = Exception('no tts');
    await say(rig, 'agrega comprar leche');
    expect(rig.texts.last, startsWith('Listo, agregué'));
    expect(rig.controller.state, MicState.idle);
  });

  test('pending counts every task the repository reports', () async {
    await say(rig, 'agrega comprar leche');
    await say(rig, 'agrega comprar pan');
    expect(rig.texts.last, endsWith('Llevas 2 pendientes.'));
  });

  test('dispose cancels the subscription and is safe mid-save', () async {
    rig.tasks.gate = Completer<void>();
    await rig.controller.pressStart();
    rig.speech.hear('agrega comprar leche');
    final end = rig.controller.pressEnd();
    await Future<void>.delayed(Duration.zero);
    rig.controller.dispose();
    expect(rig.tasks.hasListeners, isFalse);
    rig.tasks.gate!.complete();
    await end;
  });

  test('muting stops the voice, unmuting does not', () {
    rig.muted.value = true;
    expect(rig.voice.stops, 1);
    rig.muted.value = false;
    expect(rig.voice.stops, 1);
  });

  test('pending count when the list arrives after add (empty list)', () async {
    rig.tasks.emitOnAdd = false;
    await say(rig, 'agrega comprar leche');
    expect(rig.texts.last, endsWith('Llevas 1 pendiente.'));
  });

  test(
    'pending count when the list arrives after add (one existing)',
    () async {
      rig.tasks.emit([
        const Task(id: 'x', title: 'Otra', done: false, heard: ''),
      ]);
      rig.tasks.emitOnAdd = false;
      await say(rig, 'agrega comprar leche');
      expect(rig.texts.last, endsWith('Llevas 2 pendientes.'));
    },
  );

  test('a failing speech.start tells the person and returns to idle', () async {
    rig.speech.startError = Exception('boom');
    await rig.controller.pressStart();
    expect(rig.texts.last, replySpeechUnavailable);
    expect(rig.controller.state, MicState.idle);
    expect(rig.voice.spoken, [replySpeechUnavailable]);
  });

  test(
    'a press during a slow cancel waits and the hint does not return',
    () async {
      await rig.controller.pressStart();
      rig.controller.dragUpdate(-100);
      rig.speech.cancelGate = Completer<void>();
      final release = rig.controller.pressEnd();
      await Future<void>.delayed(Duration.zero);
      expect(rig.controller.hint, 'Cancelado');

      final press = rig.controller.pressStart();
      await Future<void>.delayed(Duration.zero);
      expect(rig.controller.hint, isNot('Cancelado'));
      expect(rig.speech.starts, 1);

      rig.speech.cancelGate!.complete();
      await release;
      await press;
      expect(rig.controller.state, MicState.listening);
      expect(rig.speech.starts, 2);
      expect(rig.controller.hint, isNot('Cancelado'));
    },
  );

  test('dispose while listening cancels the recognizer', () async {
    await rig.controller.pressStart();
    rig.controller.dispose();
    expect(rig.speech.cancelled, 1);
  });

  test('a synchronous failure of voice.speak is ignored', () async {
    final r = Rig(customVoice: SyncThrowingVoice());
    addTearDown(r.controller.dispose);
    await say(r, 'agrega comprar leche');
    expect(r.tasks.added.length, 1);
    expect(r.texts.last, startsWith('Listo, agregué'));
    expect(r.controller.state, MicState.idle);
  });
}
