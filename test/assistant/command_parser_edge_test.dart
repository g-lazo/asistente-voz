import 'dart:math';

import 'package:asistente_voz/assistant/command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

final thu = DateTime(2026, 11, 19); // Thursday

void task(String heard, String title, [DateTime? due, DateTime? today]) {
  final t = parseCommand(heard, today ?? thu);
  expect(t, isNotNull, reason: 'input: "$heard"');
  expect(t!.title, title, reason: 'input: "$heard"');
  expect(t.dueDate, due, reason: 'input: "$heard"');
}

void none(String heard, [DateTime? today]) {
  expect(parseCommand(heard, today ?? thu), isNull, reason: 'input: "$heard"');
}

const dayNames = {
  1: 'lunes',
  2: 'martes',
  3: 'miércoles',
  4: 'jueves',
  5: 'viernes',
  6: 'sábado',
  7: 'domingo',
};

// Independent oracle: first day strictly after [t] that has weekday [target].
DateTime nextWeekday(DateTime t, int target) {
  for (var n = 1; n <= 7; n++) {
    final d = DateTime.utc(t.year, t.month, t.day + n);
    if (d.weekday == target) return DateTime(d.year, d.month, d.day);
  }
  throw StateError('unreachable');
}

void main() {
  group('noise and whitespace', () {
    test('case, tabs, newlines, nbsp, punctuation', () {
      task('AGREGA   comprar\tleche', 'Comprar leche');
      task('agrega\tcomprar\nleche', 'Comprar leche');
      task('agrega comprar leche', 'Comprar leche');
      task('Agrega, comprar leche?', 'Comprar leche');
      task('¿Agrega comprar leche?', 'Comprar leche');
      task('agrega: comprar leche', 'Comprar leche');
      task('agrega "comprar leche"', 'Comprar leche');
      task('agrega ¿comprar leche?', 'Comprar leche');
      task('agrega . comprar leche', 'Comprar leche');
      task('  \t agrega comprar leche \n', 'Comprar leche');
      task(
        'ANOTA ENTREGAR EL REPORTE PARA MAÑANA',
        'ENTREGAR EL REPORTE',
        DateTime(2026, 11, 20),
      );
      task('AÑADE CITA EL MIÉRCOLES', 'CITA', DateTime(2026, 11, 25));
    });
    test('heard is trimmed only', () {
      expect(
        parseCommand('\n agrega  comprar\tleche \t', thu)!.heard,
        'agrega  comprar\tleche',
      );
    });
    test('nothing to say', () {
      none('');
      none(' \t\n');
      none('agrega.');
      none('agrega ...');
      none('¿?');
      none('agrega  ,  ');
      none('"');
      none('agrega ¡!');
    });
    test('all triggers', () {
      for (final w in [
        'agrega',
        'agregar',
        'añade',
        'anade',
        'añadir',
        'anadir',
        'anota',
        'anotar',
        'recuérdame',
        'recuerdame',
        'Recuérdame',
      ]) {
        task('$w comprar leche', 'Comprar leche');
      }
    });
    test('triggers only count at the first word', () {
      task('comprar leche agrega', 'Comprar leche agrega');
      task('agrega agrega', 'Agrega');
      task('agrega agrega comprar', 'Agrega comprar');
      task('agrega anota comprar', 'Anota comprar');
      task('agrégame comprar leche', 'Agrégame comprar leche');
      task('recuérdame recuérdame', 'Recuérdame');
    });
  });

  group('connectors', () {
    test('each connector', () {
      task('agrega la tarea de lavar el carro', 'Lavar el carro');
      task('agrega una tarea de lavar el carro', 'Lavar el carro');
      task('agrega la tarea lavar el carro', 'Lavar el carro');
      task('agrega una tarea lavar el carro', 'Lavar el carro');
      task('recuérdame que llame a Ana', 'Llame a Ana');
      task('Agrega la tarea de lavar', 'Lavar');
    });
    test('connector alone or with nothing behind it', () {
      none('agrega que');
      none('agrega la tarea');
      none('agrega una tarea de');
      none('agrega la tarea de');
      none('recuérdame que');
    });
    test('only one connector, only right after the trigger', () {
      task('agrega la tarea que lavar', 'Que lavar');
      task('agrega que la tarea', 'La tarea');
      task('agrega que que', 'Que');
      task('que comprar leche', 'Que comprar leche');
      task('la tarea de lavar', 'La tarea de lavar');
      task('agrega comprar que leche', 'Comprar que leche');
    });
    test('connector then date at the start', () {
      task(
        'recuérdame que mañana pague la luz',
        'Pague la luz',
        DateTime(2026, 11, 20),
      );
      task(
        'agrega la tarea de mañana comprar pan',
        'Comprar pan',
        DateTime(2026, 11, 20),
      );
      task(
        'recuérdame que el viernes pague la luz',
        'Pague la luz',
        DateTime(2026, 11, 20),
      );
      none('agrega la tarea de mañana');
    });
  });

  group('relative days', () {
    test('hoy, mañana, pasado mañana at end and start, with para', () {
      final d19 = DateTime(2026, 11, 19);
      final d20 = DateTime(2026, 11, 20);
      final d21 = DateTime(2026, 11, 21);
      task('agrega ir al banco hoy', 'Ir al banco', d19);
      task('agrega ir al banco para hoy', 'Ir al banco', d19);
      task('agrega ir al banco mañana', 'Ir al banco', d20);
      task('agrega ir al banco MAÑANA.', 'Ir al banco', d20);
      task('agrega ir al banco ¡mañana!', 'Ir al banco', d20);
      task('agrega ir al banco, para mañana', 'Ir al banco', d20);
      task('agrega ir al banco pasado mañana', 'Ir al banco', d21);
      task('agrega ir al banco pasado manana', 'Ir al banco', d21);
      task('agrega ir al banco para pasado mañana', 'Ir al banco', d21);
      task('agrega ir al banco   pasado   mañana', 'Ir al banco', d21);
      task('agrega hoy ir al banco', 'Ir al banco', d19);
      task('agrega para hoy ir al banco', 'Ir al banco', d19);
      task('agrega para mañana ir al banco', 'Ir al banco', d20);
      task('agrega pasado mañana ir al banco', 'Ir al banco', d21);
      task('agrega para pasado mañana ir al banco', 'Ir al banco', d21);
      task('pasado mañana ir al banco', 'Ir al banco', d21);
      task('mañana, ir al banco', 'Ir al banco', d20);
    });
    test('pasado alone is not a date; mañana alone is no task', () {
      task('agrega pasado', 'Pasado');
      task('agrega ir pasado', 'Ir pasado');
      none('mañana');
      none('hoy');
      none('pasado mañana');
      none('agrega para mañana');
      none('agrega pasado mañana');
      none('agrega el viernes');
      none('agrega para el 25 de noviembre');
      none('agrega este sábado');
    });
    test('date word in the middle stays in the title', () {
      task(
        'agrega ir al banco mañana a las cinco',
        'Ir al banco mañana a las cinco',
      );
      task('agrega comprar hoy leche', 'Comprar hoy leche');
      task('agrega llamar el viernes a mamá', 'Llamar el viernes a mamá');
    });
    test('para / el / este left after removal are dropped', () {
      task(
        'agrega ir al banco de mañana',
        'Ir al banco',
        DateTime(2026, 11, 20),
      );
      task(
        'agrega ir al banco este para mañana',
        'Ir al banco',
        DateTime(2026, 11, 20),
      );
      task('agrega ir al banco el hoy', 'Ir al banco', DateTime(2026, 11, 19));
      task(
        'agrega ir al banco para el pasado mañana',
        'Ir al banco',
        DateTime(2026, 11, 21),
      );
    });
    test('trailing filler without a date is kept', () {
      task('agrega comprar leche para', 'Comprar leche para');
      task('agrega comprar leche de', 'Comprar leche de');
      task('agrega comprar leche el', 'Comprar leche el');
    });
    test('filler only title after date removal', () {
      none('agrega el mañana');
      none('agrega para el hoy');
    });
    test('repeated dates: the end wins, the other stays in the title', () {
      task('agrega hoy hoy', 'Hoy', DateTime(2026, 11, 19));
      task(
        'agrega pasado mañana mañana',
        'Pasado mañana',
        DateTime(2026, 11, 20),
      );
    });
  });

  group('weekdays', () {
    test('every weekday from every weekday, all forms, end and start', () {
      for (var i = 0; i < 7; i++) {
        final today = DateTime(2026, 11, 16 + i); // Monday .. Sunday
        expect(today.weekday, i + 1);
        for (final target in dayNames.keys) {
          final name = dayNames[target]!;
          final want = nextWeekday(today, target);
          for (final prefix in ['el', 'este', 'para el', 'para este']) {
            task(
              'agrega ir al banco $prefix $name',
              'Ir al banco',
              want,
              today,
            );
            task(
              'agrega $prefix $name ir al banco',
              'Ir al banco',
              want,
              today,
            );
          }
          task(
            'agrega ir al banco el ${name.toUpperCase()}.',
            'Ir al banco',
            want,
            today,
          );
          final plain = name.replaceAll('á', 'a').replaceAll('é', 'e');
          task('agrega ir al banco el $plain', 'Ir al banco', want, today);
        }
      }
    });
    test('the article is required', () {
      task('agrega ver a Domingo', 'Ver a Domingo');
      task('agrega ir al banco viernes', 'Ir al banco viernes');
      task('agrega ir al banco para viernes', 'Ir al banco para viernes');
      task(
        'agrega ir al banco el viernes pasado',
        'Ir al banco el viernes pasado',
      );
    });
    test('same weekday is a week ahead', () {
      task(
        'agrega ir al banco el jueves',
        'Ir al banco',
        DateTime(2026, 11, 26),
      );
      task(
        'agrega ir al banco este jueves',
        'Ir al banco',
        DateTime(2026, 11, 26),
      );
    });
    test('crossing month and year', () {
      task(
        'agrega ir al banco el lunes',
        'Ir al banco',
        DateTime(2027, 1, 4),
        DateTime(2026, 12, 29),
      );
      task(
        'agrega ir al banco el viernes',
        'Ir al banco',
        DateTime(2027, 1, 8),
        DateTime(2027, 1, 1),
      );
    });
  });

  group('day and month', () {
    test('every month, this year or next', () {
      const months = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      final today = DateTime(2026, 6, 15);
      for (var m = 1; m <= 12; m++) {
        final year = m >= 6 ? 2026 : 2027;
        for (final form in [
          'el 20 de ${months[m - 1]}',
          'para el 20 de ${months[m - 1]}',
          '20 de ${months[m - 1].toUpperCase()}',
          'para 20 de ${months[m - 1]}',
        ]) {
          task(
            'agrega ir al banco $form',
            'Ir al banco',
            DateTime(year, m, 20),
            today,
          );
          task(
            'agrega $form ir al banco',
            'Ir al banco',
            DateTime(year, m, 20),
            today,
          );
        }
      }
    });
    test('today, yesterday, tomorrow in day and month', () {
      task('agrega pagar el 19 de noviembre', 'Pagar', DateTime(2026, 11, 19));
      task('agrega pagar el 18 de noviembre', 'Pagar', DateTime(2027, 11, 18));
      task('agrega pagar el 20 de noviembre', 'Pagar', DateTime(2026, 11, 20));
    });
    test('day numbers 0, 1, 31, 32 and friends', () {
      task('agrega pagar el 1 de enero', 'Pagar', DateTime(2027, 1, 1));
      task('agrega pagar el 01 de enero', 'Pagar', DateTime(2027, 1, 1));
      task('agrega pagar el 31 de enero', 'Pagar', DateTime(2027, 1, 31));
      task('agrega pagar el 31 de diciembre', 'Pagar', DateTime(2026, 12, 31));
      task('agrega pagar el 0 de enero', 'Pagar el 0 de enero');
      task('agrega pagar el 00 de enero', 'Pagar el 00 de enero');
      task('agrega pagar el 32 de enero', 'Pagar el 32 de enero');
      task('agrega pagar el 32 de diciembre', 'Pagar el 32 de diciembre');
      task('agrega pagar el 100 de enero', 'Pagar el 100 de enero');
      task('agrega pagar el 001 de enero', 'Pagar el 001 de enero');
      task('agrega pagar el 31 de abril', 'Pagar el 31 de abril');
      task('agrega pagar el 31 de junio', 'Pagar el 31 de junio');
      task('agrega pagar el 31 de septiembre', 'Pagar el 31 de septiembre');
      task('agrega pagar el 31 de noviembre', 'Pagar el 31 de noviembre');
      task('agrega pagar el 30 de febrero', 'Pagar el 30 de febrero');
      // Surrounding punctuation is folded away, so "-5" reads as 5.
      task('agrega pagar el -5 de enero', 'Pagar', DateTime(2027, 1, 5));
    });
    test('29 de febrero', () {
      // Non-leap year: the date does not exist, so it is not a date.
      task('agrega cita el 29 de febrero', 'Cita el 29 de febrero');
      // Leap year, still ahead.
      task(
        'agrega cita el 29 de febrero',
        'Cita',
        DateTime(2028, 2, 29),
        DateTime(2028, 1, 10),
      );
      task(
        'agrega cita el 29 de febrero',
        'Cita',
        DateTime(2028, 2, 29),
        DateTime(2028, 2, 29),
      );
      task(
        'agrega cita el 28 de febrero',
        'Cita',
        DateTime(2029, 2, 28),
        DateTime(2028, 3, 1),
      );
    });
    test('not date shapes', () {
      task('agrega pagar el 25', 'Pagar el 25');
      task('agrega pagar el 25 de', 'Pagar el 25 de');
      task('agrega pagar 25 de noviembre', 'Pagar', DateTime(2026, 11, 25));
      task('agrega 3 de leche', '3 de leche');
      task('agrega comprar 12 huevos', 'Comprar 12 huevos');
      task(
        'agrega comprar el 25 de noviembre cervezas',
        'Comprar el 25 de noviembre cervezas',
      );
      task(
        'agrega pagar el veinticinco de noviembre',
        'Pagar el veinticinco de noviembre',
      );
      task('agrega pagar el 25 de setiembre', 'Pagar el 25 de setiembre');
      task('agrega pagar el 25 del noviembre', 'Pagar el 25 del noviembre');
      task('agrega pagar el 25 noviembre', 'Pagar el 25 noviembre');
    });
    test('punctuation inside and around the date', () {
      task(
        'agrega ir al banco el 25 de noviembre.',
        'Ir al banco',
        DateTime(2026, 11, 25),
      );
      task(
        'agrega ir al banco, el 25 de noviembre',
        'Ir al banco',
        DateTime(2026, 11, 25),
      );
      task(
        'agrega ir al banco el 25, de noviembre',
        'Ir al banco',
        DateTime(2026, 11, 25),
      );
      task(
        'agrega ir al banco el   25   de   noviembre',
        'Ir al banco',
        DateTime(2026, 11, 25),
      );
    });
  });

  group('today and year rollover', () {
    final dec31 = DateTime(2026, 12, 31);
    test('31 December', () {
      task('agrega x hoy', 'X', DateTime(2026, 12, 31), dec31);
      task('agrega x mañana', 'X', DateTime(2027, 1, 1), dec31);
      task('agrega x pasado mañana', 'X', DateTime(2027, 1, 2), dec31);
      task('agrega x el 31 de diciembre', 'X', DateTime(2026, 12, 31), dec31);
      task('agrega x el 1 de enero', 'X', DateTime(2027, 1, 1), dec31);
      task('agrega x el 30 de diciembre', 'X', DateTime(2027, 12, 30), dec31);
      task('agrega x el jueves', 'X', DateTime(2027, 1, 7), dec31);
      task('agrega x el viernes', 'X', DateTime(2027, 1, 1), dec31);
    });
    test('month ends', () {
      task(
        'agrega x mañana',
        'X',
        DateTime(2028, 2, 29),
        DateTime(2028, 2, 28),
      );
      task('agrega x mañana', 'X', DateTime(2026, 3, 1), DateTime(2026, 2, 28));
      task(
        'agrega x pasado mañana',
        'X',
        DateTime(2027, 1, 1),
        DateTime(2026, 12, 30),
      );
      task(
        'agrega x mañana',
        'X',
        DateTime(2026, 12, 1),
        DateTime(2026, 11, 30),
      );
    });
    test('today carrying a time of day or UTC', () {
      final late = DateTime(2026, 11, 19, 23, 59, 59, 999);
      final early = DateTime(2026, 11, 19, 0, 0, 0, 1);
      for (final t in [late, early]) {
        task('agrega x hoy', 'X', DateTime(2026, 11, 19), t);
        task('agrega x mañana', 'X', DateTime(2026, 11, 20), t);
        task('agrega x el 19 de noviembre', 'X', DateTime(2026, 11, 19), t);
        task('agrega x el 18 de noviembre', 'X', DateTime(2027, 11, 18), t);
        task('agrega x el jueves', 'X', DateTime(2026, 11, 26), t);
      }
      final r = parseCommand('agrega x mañana', late)!;
      expect(r.dueDate!.hour, 0);
      expect(r.dueDate!.minute, 0);
      expect(r.dueDate!.isUtc, isFalse);
      task(
        'agrega x mañana',
        'X',
        DateTime(2026, 11, 20),
        DateTime.utc(2026, 11, 19, 12),
      );
    });
  });

  group('titles', () {
    test('length 199, 200, 201, 400', () {
      for (final n in [1, 199, 200, 201, 400]) {
        final t = parseCommand('agrega ${'a' * n}', thu)!.title;
        expect(t.length, n > 200 ? 200 : n);
        expect(t, 'A${'a' * ((n > 200 ? 200 : n) - 1)}');
      }
      final d = parseCommand('agrega ${'a' * 250} mañana', thu)!;
      expect(d.title.length, 200);
      expect(d.dueDate, DateTime(2026, 11, 20));
      final p = parseCommand('agrega ...${'a' * 300}...', thu)!;
      expect(p.title.length, 200);
      expect(p.title.startsWith('.'), isFalse);
      final nt = parseCommand('a' * 300, thu)!;
      expect(nt.title.length, 200);
    });
    test('first character', () {
      task('agrega ñandú', 'Ñandú');
      task('agrega éxito', 'Éxito');
      task('agrega 3 huevos', '3 huevos');
      task('agrega 3 huevos mañana', '3 huevos', DateTime(2026, 11, 20));
      task('agrega #pan', '#pan');
      task('agrega (pan)', '(pan)');
      task('agrega -pan', '-pan');
      task("agrega 'pan'", "'pan'");
    });
    test('emoji and digits', () {
      task('agrega comprar 🍞 mañana', 'Comprar 🍞', DateTime(2026, 11, 20));
      task('agrega 🍞 pan', '🍞 pan');
      task('agrega comprar 2kg de pan', 'Comprar 2kg de pan');
    });
    test('trigger like words inside', () {
      task('agrega que que que', 'Que que');
    });
    test('long input', () {
      final big = 'agrega ${'palabra ' * 100000}mañana';
      final sw = Stopwatch()..start();
      final r = parseCommand(big, thu)!;
      expect(r.title.length, 199); // cut at 200 lands on a space, trimmed
      expect(r.dueDate, DateTime(2026, 11, 20));
      expect(sw.elapsedMilliseconds, lessThan(5000));
      final blank = parseCommand(' ' * 500000, thu);
      expect(blank, isNull);
    });
  });

  group('fuzz invariants', () {
    test('random phrases never throw and keep the invariants', () {
      const vocab = [
        'agrega',
        'anota',
        'recuérdame',
        'añade',
        'que',
        'la',
        'tarea',
        'una',
        'de',
        'el',
        'este',
        'para',
        'hoy',
        'mañana',
        'pasado',
        'viernes',
        'domingo',
        'jueves',
        'lunes',
        'miércoles',
        '25',
        '0',
        '31',
        '32',
        '5',
        'noviembre',
        'febrero',
        'enero',
        'diciembre',
        'comprar',
        'leche',
        'ñandú',
        'á',
        '¿',
        '?',
        '.',
        ',',
        '"',
        '🍞',
        '',
        'MAÑANA',
        'El',
        'Para',
        'a',
        'las',
        'cinco',
        '29',
        '1',
        'de',
        'del',
        'abril',
      ];
      final rnd = Random(42);
      final todays = [
        DateTime(2026, 11, 19),
        DateTime(2026, 12, 31, 23, 59),
        DateTime(2028, 2, 29),
        DateTime(2027, 1, 1),
        DateTime(2026, 2, 28, 12),
      ];
      for (var i = 0; i < 10000; i++) {
        final n = rnd.nextInt(9);
        final heard = List.generate(n, (_) {
          final w = vocab[rnd.nextInt(vocab.length)];
          return rnd.nextInt(6) == 0
              ? '$w${[',', '.', '?'][rnd.nextInt(3)]}'
              : w;
        }).join(rnd.nextBool() ? ' ' : '  ');
        final today = todays[rnd.nextInt(todays.length)];
        ParsedTask? r;
        try {
          r = parseCommand(heard, today);
        } catch (e) {
          fail('threw on "$heard" today=$today: $e');
        }
        if (r == null) continue;
        final reason =
            'input "$heard" today=$today -> "${r.title}" ${r.dueDate}';
        expect(r.title.isNotEmpty, isTrue, reason: reason);
        expect(r.title.length, lessThanOrEqualTo(200), reason: reason);
        expect(
          r.title,
          isNot(matches(RegExp(r'^[.,;:!?¿¡"\s]'))),
          reason: reason,
        );
        final first = r.title[0];
        expect(first, first.toUpperCase(), reason: reason);
        expect(r.heard, heard.trim(), reason: reason);
        final d = r.dueDate;
        if (d != null) {
          final t0 = DateTime(today.year, today.month, today.day);
          expect(d, DateTime(d.year, d.month, d.day), reason: reason);
          expect(d.isBefore(t0), isFalse, reason: reason);
          expect(
            d.difference(t0).inDays,
            lessThanOrEqualTo(366),
            reason: reason,
          );
        }
      }
    });
  });
}
