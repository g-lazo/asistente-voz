/// A sign-in or sign-up failure with a message ready to show the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

/// Maps a FirebaseAuthException code to a Spanish message.
String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'El correo no es válido.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos.';
    case 'email-already-in-use':
      return 'Ese correo ya tiene una cuenta.';
    case 'weak-password':
      return 'La contraseña debe tener al menos 6 caracteres.';
    case 'network-request-failed':
      return 'Sin conexión. Revisa tu internet.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera un momento.';
    default:
      return 'No se pudo completar. Inténtalo otra vez.';
  }
}
