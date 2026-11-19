import 'package:asistente_voz/assistant/command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 19); // Thursday
  void expectTask(String heard, String title, [DateTime? due]) {
    final t = parseCommand(heard, today);
    expect(t, isNotNull, reason: heard);
    expect(t!.title, title, reason: heard);
    expect(t.dueDate, due, reason: heard);
  }

  test('spec table', () {
    expectTask('agrega comprar leche', 'Comprar leche');
    expectTask('comprar leche', 'Comprar leche');
    expectTask('recuérdame pagar el internet el viernes', 'Pagar el internet', DateTime(2026, 11, 20));
    expectTask('anota entregar el reporte para mañana', 'Entregar el reporte', DateTime(2026, 11, 20));
    expectTask('agrega llamar a mamá pasado mañana', 'Llamar a mamá', DateTime(2026, 11, 21));
    expectTask('añade cita con el dentista el 25 de noviembre', 'Cita con el dentista', DateTime(2026, 11, 25));
    expectTask('agrega ir al gimnasio el jueves', 'Ir al gimnasio', DateTime(2026, 11, 26));
    expectTask('anota renovar la licencia el 5 de enero', 'Renovar la licencia', DateTime(2027, 1, 5));
    expect(parseCommand('agrega', today), isNull);
    expect(parseCommand('   ', today), isNull);
  });

  test('recognizer noise', () {
    expectTask('Agrega comprar leche.', 'Comprar leche');
    expectTask('RECUERDAME pagar el internet el miercoles', 'Pagar el internet', DateTime(2026, 11, 25));
    expectTask('anade lavar el carro manana', 'Lavar el carro', DateTime(2026, 11, 20));
  });

  test('connectors and position', () {
    expectTask('agrega la tarea de lavar el carro', 'Lavar el carro');
    expectTask('recuérdame que llame a Ana', 'Llame a Ana');
    expectTask('mañana comprar pan', 'Comprar pan', DateTime(2026, 11, 20));
    expectTask('agrega comprar pan este sábado', 'Comprar pan', DateTime(2026, 11, 21));
  });

  test('things that are not dates', () {
    expectTask('agrega cita el 31 de febrero', 'Cita el 31 de febrero');
    expectTask('agrega ver a Domingo', 'Ver a Domingo');
    expectTask('agrega llamar a las cinco', 'Llamar a las cinco');
  });

  test('edges', () {
    expectTask('anota comprar el periódico de hoy', 'Comprar el periódico', DateTime(2026, 11, 19));
    expectTask('agrega pagar la luz el 19 de noviembre', 'Pagar la luz', DateTime(2026, 11, 19));
    expect(parseCommand('agrega mañana', today), isNull);
    expect(parseCommand('el viernes ir al banco', DateTime(2026, 11, 20))!.dueDate, DateTime(2026, 11, 27));
    expect(parseCommand('agrega ${'a' * 250}', today)!.title.length, 200);
    expect(parseCommand('  agrega comprar leche ', today)!.heard, 'agrega comprar leche');
  });

  test('rulings after the attack', () {
    expectTask('agrega despertar a las siete de la mañana', 'Despertar a las siete de la mañana');
    expectTask('agrega correr esta mañana', 'Correr esta mañana');
    expectTask('agrega ir al mercado por la mañana', 'Ir al mercado por la mañana');
    expectTask('agrega llamar al doctor a las 8 de la manana', 'Llamar al doctor a las 8 de la manana');
    expectTask('agrega pagar la luz mañana', 'Pagar la luz', DateTime(2026, 11, 20));
    expectTask('agrega pagar la luz para mañana', 'Pagar la luz', DateTime(2026, 11, 20));
    expectTask('agrega pagar la luz pasado mañana', 'Pagar la luz', DateTime(2026, 11, 21));
    expectTask('este 25 de noviembre ir al dentista', 'Ir al dentista', DateTime(2026, 11, 25));
    expectTask('agrega ir al dentista este 25 de noviembre', 'Ir al dentista', DateTime(2026, 11, 25));
    final spaced = parseCommand('agrega ${'a' * 199} b', today)!.title;
    expect(spaced, spaced.trimRight());
    expect(spaced.length, lessThanOrEqualTo(200));
    final emoji = parseCommand('agrega ${'a' * 199}\u{1F600}', today)!.title;
    expect(emoji.length, lessThanOrEqualTo(200));
    expect(emoji.codeUnitAt(emoji.length - 1) & 0xFC00, isNot(0xD800));
  });
}
