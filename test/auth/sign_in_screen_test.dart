import 'dart:async';

import 'package:asistente_voz/auth/auth_errors.dart';
import 'package:asistente_voz/auth/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> pumpScreen(
  WidgetTester tester, {
  required Future<void> Function(String, String) onSignIn,
  required Future<void> Function(String, String) onSignUp,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: SignInScreen(onSignIn: onSignIn, onSignUp: onSignUp),
    ),
  );
}

Future<void> fillAndSubmit(
  WidgetTester tester,
  String email,
  String password,
) async {
  await tester.enterText(find.byKey(const Key('email')), email);
  await tester.enterText(find.byKey(const Key('password')), password);
  await tester.tap(find.byKey(const Key('submit')));
  await tester.pump();
}

bool submitEnabled(WidgetTester tester) {
  final button = tester.widget<ButtonStyleButton>(
    find.byKey(const Key('submit')),
  );
  return button.onPressed != null;
}

void main() {
  testWidgets('rejects a bad email and a short password without calling back', (
    tester,
  ) async {
    var calls = 0;
    Future<void> count(String e, String p) async => calls++;
    await pumpScreen(tester, onSignIn: count, onSignUp: count);

    await fillAndSubmit(tester, 'gustavo', '123456');
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    expect(calls, 0);

    await fillAndSubmit(tester, 'a@b.mx', '123');
    expect(
      find.text('La contraseña debe tener al menos 6 caracteres.'),
      findsOneWidget,
    );
    expect(calls, 0);
  });

  testWidgets('trims the email and signs in', (tester) async {
    final got = <(String, String)>[];
    await pumpScreen(
      tester,
      onSignIn: (e, p) async => got.add((e, p)),
      onSignUp: (e, p) async {},
    );

    await fillAndSubmit(tester, ' a@b.mx ', '123456');
    expect(got, [('a@b.mx', '123456')]);
  });

  testWidgets('toggle switches to sign-up', (tester) async {
    var signIns = 0;
    var signUps = 0;
    await pumpScreen(
      tester,
      onSignIn: (e, p) async => signIns++,
      onSignUp: (e, p) async => signUps++,
    );
    expect(find.text('Iniciar sesión'), findsWidgets);

    await tester.tap(find.byKey(const Key('toggleMode')));
    await tester.pump();
    expect(find.text('Crear cuenta'), findsWidgets);

    await fillAndSubmit(tester, 'a@b.mx', '123456');
    expect(signUps, 1);
    expect(signIns, 0);
  });

  testWidgets('shows the failure message', (tester) async {
    await pumpScreen(
      tester,
      onSignIn: (e, p) async =>
          throw const AuthFailure('Correo o contraseña incorrectos.'),
      onSignUp: (e, p) async {},
    );

    await fillAndSubmit(tester, 'a@b.mx', '123456');
    await tester.pump();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('shows a generic message for unexpected errors', (tester) async {
    await pumpScreen(
      tester,
      onSignIn: (e, p) async => throw StateError('boom'),
      onSignUp: (e, p) async {},
    );

    await fillAndSubmit(tester, 'a@b.mx', '123456');
    await tester.pump();
    expect(
      find.text('No se pudo completar. Inténtalo otra vez.'),
      findsOneWidget,
    );
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('disables submit while the callback runs', (tester) async {
    final done = Completer<void>();
    await pumpScreen(
      tester,
      onSignIn: (e, p) => done.future,
      onSignUp: (e, p) async {},
    );

    await fillAndSubmit(tester, 'a@b.mx', '123456');
    expect(submitEnabled(tester), isFalse);

    done.complete();
    await tester.pump();
    expect(submitEnabled(tester), isTrue);
  });
}
