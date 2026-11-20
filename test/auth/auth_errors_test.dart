import 'package:flutter_test/flutter_test.dart';
import 'package:asistente_voz/auth/auth_errors.dart';

void main() {
  test('maps credential errors to one message', () {
    const expected = 'Correo o contraseña incorrectos.';
    expect(authErrorMessage('user-not-found'), expected);
    expect(authErrorMessage('wrong-password'), expected);
    expect(authErrorMessage('invalid-credential'), expected);
  });

  test('maps the remaining known codes', () {
    expect(authErrorMessage('invalid-email'), 'El correo no es válido.');
    expect(
      authErrorMessage('email-already-in-use'),
      'Ese correo ya tiene una cuenta.',
    );
    expect(
      authErrorMessage('weak-password'),
      'La contraseña debe tener al menos 6 caracteres.',
    );
    expect(
      authErrorMessage('network-request-failed'),
      'Sin conexión. Revisa tu internet.',
    );
    expect(
      authErrorMessage('too-many-requests'),
      'Demasiados intentos. Espera un momento.',
    );
  });

  test('falls back for unknown codes', () {
    expect(
      authErrorMessage('something-new'),
      'No se pudo completar. Inténtalo otra vez.',
    );
  });

  test('AuthFailure carries its message', () {
    expect(const AuthFailure('x').message, 'x');
  });
}
