import 'package:asistente_voz/tasks/task.dart';
import 'package:asistente_voz/tasks/tasks_tab.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Task _task(String id, String title, {bool done = false, DateTime? due}) =>
    Task(id: id, title: title, done: done, heard: '', dueDate: due);

Future<void> _pump(
  WidgetTester tester,
  List<Task> tasks, {
  void Function(Task, bool)? onToggle,
  void Function(Task)? onDelete,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: TasksTab(
        tasks: tasks,
        today: DateTime(2026, 11, 19),
        onToggle: onToggle ?? (_, _) {},
        onDelete: onDelete ?? (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets('empty state', (tester) async {
    await _pump(tester, const []);
    expect(
      find.text('Aún no tienes tareas. Ve al Asistente y dicta la primera.'),
      findsOneWidget,
    );
  });

  testWidgets('row shows title and date label', (tester) async {
    await _pump(tester, [
      _task('1', 'Pagar el internet', due: DateTime(2026, 11, 20)),
    ]);
    expect(find.text('Pagar el internet'), findsOneWidget);
    expect(find.text('Mañana'), findsOneWidget);
  });

  testWidgets('overdue pending date is red, a done one is not', (tester) async {
    await _pump(tester, [
      _task('1', 'Vencida', due: DateTime(2026, 11, 18)),
      _task('2', 'Hecha', done: true, due: DateTime(2026, 11, 18)),
      _task('3', 'Para hoy', due: DateTime(2026, 11, 19)),
    ]);
    final error = Theme.of(tester.element(find.text('Vencida')))
        .colorScheme
        .error;
    Color? colorOf(String label, int index) =>
        tester.widget<Text>(find.text(label).at(index)).style?.color;
    expect(colorOf('Ayer', 0), error);
    expect(colorOf('Ayer', 1), isNot(error));
    expect(colorOf('Hoy', 0), isNot(error));
  });

  testWidgets('today with a time of day is not overdue', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TasksTab(
            tasks: [
              _task('1', 'Tarea de hoy', due: DateTime(2026, 11, 20)),
              _task('2', 'Tarea de ayer', due: DateTime(2026, 11, 19)),
            ],
            today: DateTime(2026, 11, 20, 15, 30),
            onToggle: (_, _) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );
    final error = Theme.of(tester.element(find.text('Tarea de hoy')))
        .colorScheme
        .error;
    Color? colorOf(String label) =>
        tester.widget<Text>(find.text(label)).style?.color;
    expect(colorOf('Hoy'), isNot(error));
    expect(colorOf('Ayer'), error);
  });

  testWidgets('checkbox calls onToggle with the new value', (tester) async {
    final calls = <(String, bool)>[];
    await _pump(tester, [
      _task('1', 'Algo'),
    ], onToggle: (t, done) => calls.add((t.id, done)));
    await tester.tap(find.byType(Checkbox));
    expect(calls, [('1', true)]);
  });

  testWidgets('delete asks first', (tester) async {
    final calls = <String>[];
    await _pump(tester, [_task('1', 'Algo')], onDelete: (t) => calls.add(t.id));

    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar esta tarea?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(calls, ['1']);
  });

  testWidgets('pending and done tasks sit under their section labels', (
    tester,
  ) async {
    await _pump(tester, [
      _task('1', 'Primera'),
      _task('2', 'Segunda'),
      _task('3', 'Tercera', done: true),
    ]);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Hechas'), findsOneWidget);
    final hechasY = tester.getTopLeft(find.text('Hechas')).dy;
    expect(tester.getTopLeft(find.text('Pendientes')).dy, lessThan(hechasY));
    expect(tester.getTopLeft(find.text('Primera')).dy, lessThan(hechasY));
    expect(tester.getTopLeft(find.text('Segunda')).dy, lessThan(hechasY));
    expect(tester.getTopLeft(find.text('Tercera')).dy, greaterThan(hechasY));
  });

  testWidgets('a section label is hidden when its section is empty', (
    tester,
  ) async {
    await _pump(tester, [_task('1', 'Primera')]);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Hechas'), findsNothing);
    await _pump(tester, [_task('2', 'Segunda', done: true)]);
    expect(find.text('Pendientes'), findsNothing);
    expect(find.text('Hechas'), findsOneWidget);
  });

  testWidgets('the chip shows the relative label and no chip without a date', (
    tester,
  ) async {
    await _pump(tester, [
      _task('1', 'Con fecha', due: DateTime(2026, 11, 20)),
      _task('2', 'Sin fecha'),
    ]);
    expect(find.text('Mañana'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(4));
  });

  testWidgets('a task titled like a chip label shows both', (tester) async {
    final calls = <(String, bool)>[];
    await _pump(tester, [
      _task('1', 'Hoy', due: DateTime(2026, 11, 19)),
    ], onToggle: (t, done) => calls.add((t.id, done)));
    expect(find.text('Hoy'), findsNWidgets(2));
    await tester.tap(find.byType(Checkbox));
    expect(calls, [('1', true)]);
  });

  testWidgets('a 200-character title fits a 320 px card', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, [_task('1', 'a' * 200, due: DateTime(2026, 11, 20))]);
    expect(tester.takeException(), isNull);
    expect(find.text('Mañana'), findsOneWidget);
    expect(find.byTooltip('Eliminar'), findsOneWidget);
  });
}
