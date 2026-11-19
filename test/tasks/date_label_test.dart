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
}
