import 'dart:async';

import 'package:asistente_voz/assistant/command_parser.dart';
import 'package:asistente_voz/home/home_screen.dart';
import 'package:asistente_voz/tasks/task.dart';
import 'package:asistente_voz/tasks/task_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements TaskRepository {
  final controller = StreamController<List<Task>>();
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
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(tasks: repo, onSignOut: onSignOut ?? () {}),
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
}
