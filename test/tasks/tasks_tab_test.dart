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
    expect(find.text('vie 20 nov'), findsOneWidget);
  });

  testWidgets('overdue pending date is red, a done one is not', (tester) async {
    await _pump(tester, [
      _task('1', 'Vencida', due: DateTime(2026, 11, 18)),
      _task('2', 'Hecha', done: true, due: DateTime(2026, 11, 18)),
      _task('3', 'Hoy', due: DateTime(2026, 11, 19)),
    ]);
    final error = Theme.of(tester.element(find.text('Vencida')))
        .colorScheme
        .error;
    Color? colorOf(String label, int index) =>
        tester.widget<Text>(find.text(label).at(index)).style?.color;
    expect(colorOf('mié 18 nov', 0), error);
    expect(colorOf('mié 18 nov', 1), isNot(error));
    expect(colorOf('jue 19 nov', 0), isNot(error));
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
}
