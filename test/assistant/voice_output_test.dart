import 'dart:async';

import 'package:asistente_voz/assistant/voice_output.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _all = ['de-DE', 'en-US', 'es-ES', 'es-US'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Every call on the plugin's channel, in order, as `method` or `method:arg`.
  late List<String> calls;
  // What each successive `getLanguages` answers: a list, an exception, or a
  // Future the test completes by hand. The last entry repeats when it runs out.
  late List<Object> answers;

  setUp(() {
    calls = [];
    answers = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          calls.add(
            call.arguments == null
                ? call.method
                : '${call.method}:${call.arguments}',
          );
          if (call.method != 'getLanguages') return 1;
          final n = calls.where((c) => c == 'getLanguages').length;
          final answer = answers[(n - 1).clamp(0, answers.length - 1)];
          if (answer is Future) return await answer;
          if (answer is Exception) throw answer;
          return answer;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  int count(String call) => calls.where((c) => c == call).length;

  test(
    '1 a language list at construction is used by the first speak',
    () async {
      answers = [_all];
      final out = TtsVoiceOutput();
      await pumpEventQueue();
      await out.speak('hola');
      expect(calls, ['getLanguages', 'setLanguage:es-US', 'speak:hola']);
    },
  );

  test('2 an empty list is retried at the next speak', () async {
    answers = [<String>[], _all];
    final out = TtsVoiceOutput();
    await pumpEventQueue();
    await out.speak('hola');
    expect(count('getLanguages'), 2);
    expect(
      calls.indexOf('setLanguage:es-US'),
      lessThan(calls.indexOf('speak:hola')),
    );
  });

  test('3 an empty list keeps being retried until it has languages', () async {
    answers = [
      <String>[],
      <String>[],
      ['es-ES'],
    ];
    final out = TtsVoiceOutput();
    await pumpEventQueue();
    await out.speak('uno');
    await out.speak('dos');
    expect(
      calls.sublist(0, calls.indexOf('speak:uno')),
      isNot(contains('setLanguage:es-ES')),
    );
    expect(
      calls.indexOf('setLanguage:es-ES'),
      greaterThan(calls.indexOf('speak:uno')),
    );
    expect(
      calls.indexOf('setLanguage:es-ES'),
      lessThan(calls.indexOf('speak:dos')),
    );
    expect(count('getLanguages'), 3);
  });

  test('4 once settled, later speaks do not ask again', () async {
    answers = [_all];
    final out = TtsVoiceOutput();
    await pumpEventQueue();
    await out.speak('hola');
    calls.clear();
    await out.speak('otra');
    expect(calls, ['speak:otra']);
  });

  test('5 a list without Spanish settles with nothing set', () async {
    answers = [
      ['de-DE', 'en-US'],
    ];
    final out = TtsVoiceOutput();
    await pumpEventQueue();
    await out.speak('a');
    await out.speak('b');
    expect(count('getLanguages'), 1);
    expect(count('setLanguage:de-DE') + count('setLanguage:en-US'), 0);
    expect(calls.where((c) => c.startsWith('setLanguage')), isEmpty);
    expect(calls.where((c) => c.startsWith('speak')), ['speak:a', 'speak:b']);
  });

  test('6 es-MX wins over es-US and es-ES', () async {
    answers = [
      ['es-ES', 'es-US', 'es-MX'],
    ];
    final out = TtsVoiceOutput();
    await out.speak('x');
    expect(calls.where((c) => c.startsWith('setLanguage')), [
      'setLanguage:es-MX',
    ]);
  });

  test(
    '7 ids compare without case or separator and are passed as listed',
    () async {
      answers = [
        ['es_ES', 'ES_us'],
      ];
      final out = TtsVoiceOutput();
      await out.speak('x');
      expect(calls.where((c) => c.startsWith('setLanguage')), [
        'setLanguage:ES_us',
      ]);
    },
  );

  test('8 a failing getLanguages at construction is retried quietly', () async {
    answers = [
      PlatformException(code: 'boom'),
      ['es-US'],
    ];
    final out = TtsVoiceOutput();
    await pumpEventQueue();
    await out.speak('hola');
    expect(
      calls.indexOf('setLanguage:es-US'),
      lessThan(calls.indexOf('speak:hola')),
    );
    expect(count('getLanguages'), 2);
  });

  test('9 a speak during an attempt in flight waits for it', () async {
    final pending = Completer<List<String>>();
    answers = [pending.future];
    final out = TtsVoiceOutput();
    await pumpEventQueue();
    final spoken = out.speak('hola');
    await pumpEventQueue();
    expect(calls.where((c) => c.startsWith('speak')), isEmpty);
    pending.complete(['es-US']);
    await spoken;
    expect(calls, ['getLanguages', 'setLanguage:es-US', 'speak:hola']);
  });
}
