import 'package:asistente_voz/assistant/speech_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('joins finished segments and the current one with single spaces', () {
    final a = TranscriptAccumulator();
    a.update('agrega', isFinal: false);
    expect(a.text, 'agrega');
    a.update('agrega comprar', isFinal: true);
    expect(a.text, 'agrega comprar');
    a.update('leche', isFinal: false);
    expect(a.text, 'agrega comprar leche');
    a.update('leche y pan', isFinal: true);
    expect(a.text, 'agrega comprar leche y pan');
    a.reset();
    expect(a.text, '');
  });

  test('empty segments add no stray spaces', () {
    final a = TranscriptAccumulator();
    a.update('', isFinal: true);
    a.update('hola', isFinal: false);
    expect(a.text, 'hola');
  });

  test('trims segments and keeps single spaces', () {
    final a = TranscriptAccumulator();
    a.update(' uno ', isFinal: true);
    a.update(' dos', isFinal: false);
    expect(a.text, 'uno dos');
    a.update('tres   cuatro', isFinal: true);
    expect(a.text, 'uno tres cuatro');
    a.update('   ', isFinal: true);
    expect(a.text, 'uno tres cuatro');
  });
}
