import 'package:flutter_test/flutter_test.dart';
import 'package:asistente_voz/tasks/task.dart';

void main() {
  test('due date round trip', () {
    expect(encodeDueDate(DateTime(2026, 1, 5)), '2026-01-05');
    expect(encodeDueDate(null), isNull);
    expect(decodeDueDate('2026-01-05'), DateTime(2026, 1, 5));
    for (final bad in [null, 5, '', '2026-13-40', 'mañana']) {
      expect(decodeDueDate(bad), isNull);
    }
  });

  test('fromMap tolerates missing fields', () {
    final t = Task.fromMap('x', {'title': 'Comprar leche'});
    expect([t.id, t.title, t.done, t.heard, t.dueDate, t.createdAt],
        ['x', 'Comprar leche', false, '', null, null]);
  });

  test('sort order', () {
    Task t(String id, {bool done = false, DateTime? due, DateTime? at}) => Task(
        id: id, title: id, done: done, heard: '', dueDate: due, createdAt: at);
    final sorted = sortTasks([
      t('done', done: true, at: DateTime(2026, 11, 19)),
      t('undated-old', at: DateTime(2026, 11, 1)),
      t('late', due: DateTime(2026, 12, 1)),
      t('undated-new', at: DateTime(2026, 11, 18)),
      t('soon', due: DateTime(2026, 11, 20)),
      t('just-written'),
    ]);
    expect(sorted.map((e) => e.id),
        ['soon', 'late', 'just-written', 'undated-new', 'undated-old', 'done']);
    expect(pendingCount(sorted), 5);
  });
}
