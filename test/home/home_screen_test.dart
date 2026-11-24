import 'dart:async';

import 'package:asistente_voz/assistant/command_parser.dart';
import 'package:asistente_voz/assistant/mute_setting.dart';
import 'package:asistente_voz/assistant/speech_input.dart';
import 'package:asistente_voz/assistant/voice_output.dart';
import 'package:asistente_voz/home/home_screen.dart';
import 'package:asistente_voz/tasks/date_label.dart';
import 'package:asistente_voz/tasks/task.dart';
import 'package:asistente_voz/tasks/task_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSpeech implements SpeechInput {
  @override
  Future<SpeechStatus> prepare() async => SpeechStatus.ready;

  @override
  Future<void> start(void Function(String text) onText) async {}

  @override
  Future<String> stop() async => '';

  @override
  Future<void> cancel() async {}
}

class _FakeVoice implements VoiceOutput {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

class _FakeRepository implements TaskRepository {
  // Broadcast: the screen and the assistant controller both listen.
  final controller = StreamController<List<Task>>.broadcast();
  final calls = <String>[];
  Object? failWith;

  @override
  Stream<List<Task>> watch() => controller.stream;

  @override
  Future<void> add(ParsedTask task) async => calls.add('add ${task.title}');

  @override
  Future<void> setDone(String id, bool done) async {
    calls.add('setDone $id $done');
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete $id');
    if (failWith != null) throw failWith!;
  }
}

Task _task(String id, {bool done = false}) =>
    Task(id: id, title: 'Tarea $id', done: done, heard: '');

Future<_FakeRepository> _pump(
  WidgetTester tester, {
  VoidCallback? onSignOut,
  List<Task>? initial,
}) async {
  final repo = _FakeRepository();
  addTearDown(repo.controller.close);
  SharedPreferences.setMockInitialValues({});
  final mute = MuteSetting(await SharedPreferences.getInstance());
  addTearDown(mute.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        tasks: repo,
        onSignOut: onSignOut ?? () {},
        speech: _FakeSpeech(),
        voice: _FakeVoice(),
        mute: mute,
      ),
    ),
  );
  repo.controller.add(
    initial ?? [_task('1'), _task('2'), _task('3', done: true)],
  );
  await tester.pump();
  return repo;
}

void main() {
  testWidgets('second tab counts the pending tasks', (tester) async {
    await _pump(tester);
    expect(find.text('Mis tareas (2)'), findsOneWidget);
    expect(find.text('Asistente'), findsOneWidget);
  });

  testWidgets('sign-out button calls onSignOut once', (tester) async {
    var calls = 0;
    await _pump(tester, onSignOut: () => calls++);
    await tester.tap(find.byTooltip('Cerrar sesión'));
    expect(calls, 1);
  });

  testWidgets('mute button toggles its tooltip', (tester) async {
    await _pump(tester);
    expect(find.byTooltip('Silenciar voz'), findsOneWidget);
    await tester.tap(find.byTooltip('Silenciar voz'));
    await tester.pump();
    expect(find.byTooltip('Activar voz'), findsOneWidget);
    expect(find.byTooltip('Silenciar voz'), findsNothing);
  });

  testWidgets('sliding on the mic does not drag the page', (tester) async {
    final repo = await _pump(tester);
    final mic = find.byKey(const Key('micButton'));
    final startX = tester.getCenter(mic).dx;
    final gesture = await tester.startGesture(tester.getCenter(mic));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.getCenter(mic).dx, startX);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBarView))).index,
      0,
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getCenter(mic).dx, startX);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBarView))).index,
      0,
    );
    expect(repo.calls, isEmpty);
    expect(find.text('Cancelado'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('checkbox and confirmed delete reach the repository', (
    tester,
  ) async {
    final repo = await _pump(tester, initial: [_task('1')]);
    await tester.tap(find.text('Mis tareas (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(repo.calls, ['setDone 1 true']);

    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['setDone 1 true', 'delete 1']);
  });

  testWidgets('a failing write shows a snackbar instead of an error', (
    tester,
  ) async {
    final repo = await _pump(tester, initial: [_task('1')]);
    repo.failWith = Exception('offline');
    await tester.tap(find.text('Mis tareas (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('No se pudo completar. Inténtalo otra vez.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed stream shows an error instead of the empty state', (
    tester,
  ) async {
    final repo = await _pump(tester, initial: [_task('1')]);
    repo.controller.addError(Exception('permission-denied'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Mis tareas'), findsOneWidget);
    await tester.tap(find.text('Mis tareas'));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudieron cargar tus tareas. Revisa tu conexión.'),
      findsOneWidget,
    );
    expect(
      find.text('Aún no tienes tareas. Ve al Asistente y dicta la primera.'),
      findsNothing,
    );
  });

  testWidgets('header shows the title and today\'s date, without an app bar', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Asistente de tareas'), findsOneWidget);
    expect(find.text(headerDateLabel(DateTime.now())), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('fits 320 x 568 at text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepository();
    addTearDown(repo.controller.close);
    SharedPreferences.setMockInitialValues({});
    final mute = MuteSetting(await SharedPreferences.getInstance());
    addTearDown(mute.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: HomeScreen(
          tasks: repo,
          onSignOut: () {},
          speech: _FakeSpeech(),
          voice: _FakeVoice(),
          mute: mute,
        ),
      ),
    );
    repo.controller.add([_task('1'), _task('2')]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
