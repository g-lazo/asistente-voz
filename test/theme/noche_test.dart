import 'package:asistente_voz/theme/noche.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('theme is dark Material 3 built from the palette', () {
    final t = nocheTheme();
    expect(t.brightness, Brightness.dark);
    expect(t.useMaterial3, isTrue);
    expect(t.scaffoldBackgroundColor, Noche.background);
    expect(t.colorScheme.primary, Noche.violet);
    expect(t.colorScheme.error, Noche.danger);
  });

  testWidgets('NocheBackground shows its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NocheBackground(child: Text('x'))),
    );
    expect(find.text('x'), findsOneWidget);
  });
}
