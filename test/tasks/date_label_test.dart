import 'package:flutter_test/flutter_test.dart';
import 'package:asistente_voz/tasks/date_label.dart';

void main() {
  test('short label', () {
    expect(shortDateLabel(DateTime(2026, 11, 20)), 'vie 20 nov');
    expect(shortDateLabel(DateTime(2027, 1, 5)), 'mar 5 ene');
  });

  test('long label', () {
    expect(longDateLabel(DateTime(2026, 11, 20)), 'viernes 20 de noviembre');
    expect(longDateLabel(DateTime(2026, 11, 25)), 'miércoles 25 de noviembre');
  });

  test('header label starts with a capital letter', () {
    expect(headerDateLabel(DateTime(2026, 11, 24)), 'Martes 24 de noviembre');
    expect(
      headerDateLabel(DateTime(2026, 11, 25)),
      'Miércoles 25 de noviembre',
    );
    expect(headerDateLabel(DateTime(2026, 11, 28)), 'Sábado 28 de noviembre');
    expect(headerDateLabel(DateTime(2027, 1, 4)), 'Lunes 4 de enero');
  });

  test('chip label is relative near today and capitalised otherwise', () {
    final today = DateTime(2026, 11, 24, 15, 30);
    expect(chipDateLabel(DateTime(2026, 11, 24), today), 'Hoy');
    expect(chipDateLabel(DateTime(2026, 11, 25), today), 'Mañana');
    expect(chipDateLabel(DateTime(2026, 11, 23), today), 'Ayer');
    expect(chipDateLabel(DateTime(2026, 11, 27), today), 'Vie 27 nov');
    expect(chipDateLabel(DateTime(2026, 11, 22), today), 'Dom 22 nov');
    expect(chipDateLabel(DateTime(2026, 11, 28), today), 'Sáb 28 nov');
    expect(
      chipDateLabel(DateTime(2026, 11, 25, 23, 59), DateTime(2026, 11, 24)),
      'Mañana',
    );
    expect(
      chipDateLabel(DateTime(2026, 12, 1), DateTime(2026, 11, 30, 23, 59)),
      'Mañana',
    );
    expect(
      chipDateLabel(DateTime(2027, 1, 1), DateTime(2026, 12, 31)),
      'Mañana',
    );
    expect(chipDateLabel(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), 'Ayer');
  });
}
