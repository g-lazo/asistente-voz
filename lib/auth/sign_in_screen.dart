import 'package:material_ui/material_ui.dart';

import '../theme/noche.dart';
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NocheBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: Noche.accent,
                          boxShadow: [
                            BoxShadow(
                              color: Noche.violet.withValues(alpha: 0.5),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Asistente de tareas',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Noche.text,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: Noche.panel(radius: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            key: const Key('email'),
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: Noche.text),
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('password'),
                            controller: _password,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_busy) _submit();
                            },
                            style: const TextStyle(color: Noche.text),
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(color: scheme.error),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('submit'),
                            onPressed: _busy ? null : _submit,
                            child: Text(label),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
      ),
    );
  }
}
