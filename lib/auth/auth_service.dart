import 'package:firebase_auth/firebase_auth.dart';

import 'auth_errors.dart';

/// Thin wrapper over FirebaseAuth that turns its exceptions into [AuthFailure].
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authErrorMessage(e.code));
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authErrorMessage(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();
}
