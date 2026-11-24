import 'dart:async';

import 'package:asistente_voz/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Counts how many times its state was created, to tell a kept subtree from a
/// rebuilt one.
class _Probe extends StatefulWidget {
  const _Probe({required this.uid, required this.onInit});
  final String uid;
  final VoidCallback onInit;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => Text('in:${widget.uid}');
}

void main() {
  late StreamController<String?> controller;
  late int inits;

  setUp(() {
    controller = StreamController<String?>();
    inits = 0;
  });

  tearDown(() => controller.close());

  Future<void> pumpGate(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          uid: controller.stream,
          signedOut: (_) => const Text('out'),
          signedIn: (_, uid) => _Probe(uid: uid, onInit: () => inits++),
        ),
      ),
    );
  }

  testWidgets('shows a progress indicator before the first event',
      (tester) async {
    await pumpGate(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('out'), findsNothing);
  });

  testWidgets('shows the signed-out widget for null', (tester) async {
    await pumpGate(tester);
    controller.add(null);
    await tester.pump();
    expect(find.text('out'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('builds the signed-in widget with the uid', (tester) async {
    await pumpGate(tester);
    controller.add('u1');
    await tester.pump();
    expect(find.text('in:u1'), findsOneWidget);
    expect(inits, 1);
  });

  testWidgets('another uid starts a fresh subtree', (tester) async {
    await pumpGate(tester);
    controller.add('u1');
    await tester.pump();
    controller.add('u2');
    await tester.pump();
    expect(find.text('in:u2'), findsOneWidget);
    expect(inits, 2);
  });

  testWidgets('the same uid again keeps the state', (tester) async {
    await pumpGate(tester);
    controller.add('u1');
    await tester.pump();
    controller.add('u1');
    await tester.pump();
    expect(find.text('in:u1'), findsOneWidget);
    expect(inits, 1);
  });

  testWidgets('goes back to signed-out after a sign-out', (tester) async {
    await pumpGate(tester);
    controller.add('u1');
    await tester.pump();
    controller.add(null);
    await tester.pump();
    expect(find.text('out'), findsOneWidget);
    expect(find.text('in:u1'), findsNothing);
  });

  testWidgets('shows the signed-out widget on a stream error', (tester) async {
    await pumpGate(tester);
    controller.addError(StateError('boom'));
    await tester.pump();
    expect(find.text('out'), findsOneWidget);
  });
}
