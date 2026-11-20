import 'package:asistente_voz/assistant/assistant_controller.dart';
import 'package:asistente_voz/assistant/assistant_tab.dart';
import 'package:asistente_voz/assistant/replies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'assistant_controller_test.dart';

Future<AssistantController> pumpTab(
  WidgetTester tester,
  FakeSpeech speech, {
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final controller = AssistantController(
    speech: speech,
    voice: FakeVoice(),
    tasks: FakeTasks(),
    muted: ValueNotifier<bool>(true),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AssistantTab(controller: controller)),
    ),
  );
  return controller;
}

void main() {
  testWidgets('shows the greeting and the idle hint', (tester) async {
    await pumpTab(tester, FakeSpeech());
    expect(find.text(greeting), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('hint'))).data,
      'Mantén presionado para hablar',
    );
    expect(find.byKey(const Key('micButton')), findsOneWidget);
  });

  testWidgets(
    'pointer down on the mic starts listening and shows the partial text',
    (tester) async {
      final speech = FakeSpeech();
      final controller = await pumpTab(tester, speech);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('micButton'))),
      );
      await tester.pump();
      expect(controller.state, MicState.listening);

      speech.hear('agrega comprar leche');
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('partialText'))).data,
        'agrega comprar leche',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('hint'))).data,
        startsWith('Suelta para enviar'),
      );

      await gesture.up();
      await tester.pump();
      expect(controller.state, MicState.idle);
      expect(
        find.text('Listo, agregué "Comprar leche". Llevas 1 pendiente.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('dragging left arms the cancel', (tester) async {
    final speech = FakeSpeech();
    final controller = await pumpTab(tester, speech);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('micButton'))),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    expect(controller.state, MicState.cancelArmed);
    await gesture.up();
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('hint'))).data,
      'Cancelado',
    );
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.widget<Text>(find.byKey(const Key('hint'))).data,
      'Mantén presionado para hablar',
    );
    expect(controller.state, MicState.idle);
    expect(speech.cancelled, 1);
  });

  testWidgets('does not overflow at 320 px with a long transcript', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await pumpTab(tester, speech, size: const Size(320, 480));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('micButton'))),
    );
    await tester.pump();
    speech.hear('agrega ${'comprar leche y pan y huevos ' * 20}');
    await tester.pump();
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
