import 'package:asistente_voz/assistant/speech_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickSpeechLocale', () {
    void expectPick(List<String> ids, bool web, String? expected) {
      test('$ids web=$web -> $expected', () {
        expect(pickSpeechLocale(ids, web: web), expected);
      });
    }

    expectPick([], true, 'es-MX');
    expectPick(['en-US'], true, 'es-MX');
    expectPick(['en-US', 'es-ES'], true, 'es-ES');
    expectPick([], false, null);
    expectPick(['en_US', 'fr_FR'], false, null);
    expectPick(['en_US', 'es_ES'], false, 'es_ES');
    expectPick(['es_ES', 'es_US', 'es_MX'], false, 'es_MX');
    expectPick(['es_ES', 'es_US'], false, 'es_US');
    expectPick(['es-ES', 'es-US'], false, 'es-US');
    expectPick(['ES_mx'], false, 'ES_mx');
  });
}
