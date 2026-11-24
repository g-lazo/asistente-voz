import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:asistente_voz/web_frame/phone_frame.dart';

class _Probe extends StatelessWidget {
  const _Probe({required this.onTap, this.openDialog = false});

  final VoidCallback onTap;
  final bool openDialog;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: SizedBox.expand(
        key: const Key('probe'),
        child: Column(
          children: [
            Text('size ${size.width.toInt()}x${size.height.toInt()}'),
            Text('top ${top.toInt()}'),
            TextButton(
              key: const Key('probeButton'),
              onPressed: openDialog
                  ? () => showDialog<void>(
                      context: context,
                      builder: (_) => const AlertDialog(
                        key: Key('probeDialog'),
                        title: Text('Dialog'),
                      ),
                    )
                  : onTap,
              child: const Text('tap'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required Size window,
  required bool enabled,
  VoidCallback? onTap,
  bool openDialog = false,
}) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => PhoneFrame(enabled: enabled, child: child!),
      home: _Probe(onTap: onTap ?? () {}, openDialog: openDialog),
    ),
  );
}

// Global rectangle, so a scaled widget reports its on-screen size.
Rect _rectOf(WidgetTester tester, Finder finder) =>
    Rect.fromPoints(tester.getTopLeft(finder), tester.getBottomRight(finder));

void main() {
  testWidgets('shows a 390 x 844 phone with a 44 px top inset', (tester) async {
    await _pump(tester, window: const Size(1200, 900), enabled: true);

    expect(find.byKey(const Key('phoneBezel')), findsOneWidget);
    expect(find.text('size 390x844'), findsOneWidget);
    expect(find.text('top 44'), findsOneWidget);
  });

  testWidgets('does not scale the phone up in a large window', (tester) async {
    await _pump(tester, window: const Size(1600, 1200), enabled: true);

    final rect = _rectOf(tester, find.byKey(const Key('probe')));
    expect(rect.width, closeTo(390, 0.01));
    expect(rect.height, closeTo(844, 0.01));
  });

  testWidgets('shrinks to fit a short window and keeps taps working', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      window: const Size(1366, 600),
      enabled: true,
      onTap: () => taps++,
    );

    final bezel = _rectOf(tester, find.byKey(const Key('phoneBezel')));
    expect(bezel.height, lessThanOrEqualTo(600));
    expect(find.text('size 390x844'), findsOneWidget);

    await tester.tap(find.byKey(const Key('probeButton')));
    expect(taps, 1);
  });

  testWidgets('returns the child untouched in a phone-width window', (
    tester,
  ) async {
    await _pump(tester, window: const Size(599, 900), enabled: true);

    expect(find.byKey(const Key('phoneBezel')), findsNothing);
    expect(find.text('size 599x900'), findsOneWidget);
  });

  testWidgets('returns the child untouched when not enabled', (tester) async {
    await _pump(tester, window: const Size(1200, 900), enabled: false);

    expect(find.byKey(const Key('phoneBezel')), findsNothing);
    expect(find.text('size 1200x900'), findsOneWidget);
  });

  testWidgets('keeps dialogs inside the phone', (tester) async {
    await _pump(
      tester,
      window: const Size(1200, 900),
      enabled: true,
      openDialog: true,
    );

    await tester.tap(find.byKey(const Key('probeButton')));
    await tester.pumpAndSettle();

    final bezel = _rectOf(tester, find.byKey(const Key('phoneBezel')));
    final dialog = _rectOf(tester, find.byKey(const Key('probeDialog')));
    expect(bezel.contains(dialog.topLeft), isTrue);
    expect(bezel.contains(dialog.bottomRight), isTrue);
  });
}
