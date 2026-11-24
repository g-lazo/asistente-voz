import 'package:flutter_test/flutter_test.dart';
import 'package:asistente_voz/assistant/command_parser.dart';
import 'package:asistente_voz/assistant/replies.dart';

void main() {
  const plain = ParsedTask(title: 'Comprar leche', heard: 'agrega comprar leche');
  final dated = ParsedTask(
      title: 'Pagar el internet', heard: 'x', dueDate: DateTime(2026, 11, 20));

  test('saved reply without date, plural and singular', () {
    expect(replySaved(plain, 4),
        'Listo, agregué "Comprar leche". Llevas 4 pendientes.');
    expect(replySaved(plain, 1),
        'Listo, agregué "Comprar leche". Llevas 1 pendiente.');
  });

  test('saved reply with date', () {
    expect(replySaved(dated, 5),
        'Listo, agregué "Pagar el internet" para el viernes 20 de noviembre. Llevas 5 pendientes.');
  });

  test('spokenText drops double quotes', () {
    expect(spokenText(replySaved(plain, 4)),
        'Listo, agregué Comprar leche. Llevas 4 pendientes.');
  });

  test('greeting holds one example the parser turns into a dated task', () {
    final quoted = RegExp(r'"([^"]*)"').allMatches(greeting).toList();
    expect(quoted, hasLength(1));
    final task = parseCommand(quoted.single.group(1)!, DateTime(2026, 11, 19));
    expect(task, isNotNull);
    expect(task!.title, 'Comprar leche');
    expect(task.dueDate, DateTime(2026, 11, 20));
  });
}
