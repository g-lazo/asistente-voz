import 'package:material_ui/material_ui.dart';

import 'auth_errors.dart';

/// Email and password form that doubles as sign-up through a toggle.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
  });

  final Future<void> Function(String email, String password) onSignIn;
  final Future<void> Function(String email, String password) onSignUp;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@')) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    if (password.length < 6) {
      setState(
        () => _error = 'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      await (_signUp
          ? widget.onSignUp(email, password)
          : widget.onSignIn(email, password));
    } on AuthFailure catch (e) {
      error = e.message;
    } catch (_) {
      error = 'No se pudo completar. Inténtalo otra vez.';
    }
    // On success the parent usually swaps this screen out.
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = _signUp ? 'Crear cuenta' : 'Iniciar sesión';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Asistente de tareas',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('password'),
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(label),
                  ),
                  TextButton(
                    key: const Key('toggleMode'),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _signUp = !_signUp;
                            _error = null;
                          }),
                    child: Text(
                      _signUp
                          ? 'Ya tengo cuenta'
                          : 'No tengo cuenta, crear una',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
