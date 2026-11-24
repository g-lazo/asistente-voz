import 'package:asistente_voz/assistant/command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 19); // Thursday
  final tomorrow = DateTime(2026, 11, 20);

  void expectTask(String heard, String title, [DateTime? due]) {
    final t = parseCommand(heard, today);
    expect(t, isNotNull, reason: heard);
    expect(t!.title, title, reason: heard);
    expect(t.dueDate, due, reason: heard);
  }

  group('natural lead-ins', () {
    test('request, frame and trigger together', () {
      expectTask('quiero que añadas que tengo que hacer la tarea', 'Hacer la tarea');
      expectTask('necesito que agregues comprar pan', 'Comprar pan');
      expectTask('agrega que necesito comprar pan', 'Comprar pan');
      expectTask('QUIERO QUE ANADAS QUE TENGO QUE HACER LA TAREA', 'HACER LA TAREA');
    });

    test('frame with or without a trigger', () {
      expectTask('quiero agregar comprar leche', 'Comprar leche');
      expectTask('quiero comprar leche', 'Comprar leche');
      expectTask('tengo que hacer la tarea', 'Hacer la tarea');
      expectTask('hay que sacar la basura mañana', 'Sacar la basura', tomorrow);
      expectTask('necesito comprar pan', 'Comprar pan');
      expectTask('debo llamar al banco el viernes', 'Llamar al banco', tomorrow);
      expectTask('me gustaría agregar ir al gimnasio el jueves', 'Ir al gimnasio', DateTime(2026, 11, 26));
      expectTask('tengo que entregar el reporte para mañana', 'Entregar el reporte', tomorrow);
    });

    test('openers and courtesy', () {
      expectTask('por favor agrega comprar leche', 'Comprar leche');
      expectTask('agrega comprar leche por favor', 'Comprar leche');
      expectTask('agrega comprar leche mañana por favor', 'Comprar leche', tomorrow);
      expectTask('oye, anótame llamar a mamá', 'Llamar a mamá');
      expectTask('hola, quiero agregar comprar leche, por favor', 'Comprar leche');
    });

    test('verb forms and connectors', () {
      expectTask('agrégame comprar leche', 'Comprar leche');
      expectTask('añádeme una tarea para lavar el carro', 'Lavar el carro');
      expectTask('me recuerdas pagar el internet el viernes', 'Pagar el internet', tomorrow);
      expectTask('quiero que me recuerdes pagar la luz', 'Pagar la luz');
      expectTask('¿puedes agregar comprar leche?', 'Comprar leche');
      expectTask('podrías anotar una tarea para llamar a mamá mañana', 'Llamar a mamá', tomorrow);
      expectTask('me puedes recordar comprar pan', 'Comprar pan');
      expectTask('puedes recordarme comprar pan', 'Comprar pan');
      expectTask('agrega a mi lista comprar leche', 'Comprar leche');
    });

    test('frame after the trigger or after a leading date', () {
      expectTask('recuérdame que tengo que pagar el internet el viernes', 'Pagar el internet', tomorrow);
      expectTask('recuérdame que mañana tengo que pagar la luz', 'Pagar la luz', tomorrow);
      expectTask('mañana tengo que ir al banco', 'Ir al banco', tomorrow);
    });
  });

  group('not removed', () {
    test('words that are not a lead-in', () {
      expectTask('me toca lavar los platos', 'Me toca lavar los platos');
      expectTask('puedes comprar leche', 'Puedes comprar leche');
      expectTask('comprar pavo para acción de gracias', 'Comprar pavo para acción de gracias');
      expectTask('la tarea de lavar', 'La tarea de lavar');
      expectTask('tengo que tengo que estudiar', 'Tengo que estudiar');
      expectTask('comprar leche agrega', 'Comprar leche agrega');
      expectTask('pedir a Ana que anote la cita', 'Pedir a Ana que anote la cita');
    });
  });

  test('no task', () {
    for (final heard in [
      'quiero',
      'tengo que',
      'por favor',
      'quiero que añadas',
      'agrega por favor',
      'hola',
      'necesito que agregues',
    ]) {
      expect(parseCommand(heard, today), isNull, reason: heard);
    }
  });

  test('heard is the whole transcript, trimmed', () {
    expect(
      parseCommand('  quiero que añadas que tengo que hacer la tarea ', today)!.heard,
      'quiero que añadas que tengo que hacer la tarea',
    );
  });
}
