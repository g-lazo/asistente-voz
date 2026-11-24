import 'package:material_ui/material_ui.dart';

/// Shows [signedOut] while nobody is signed in and [signedIn] for a user id.
/// The signed-in subtree is keyed by the uid, so another account starts clean.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.uid,
    required this.signedOut,
    required this.signedIn,
  });

  final Stream<String?> uid;
  final WidgetBuilder signedOut;
  final Widget Function(BuildContext context, String uid) signedIn;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: uid,
      builder: (context, snapshot) {
        // An error means we cannot tell who is signed in; ask for credentials.
        if (snapshot.hasError) return signedOut(context);
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final id = snapshot.data;
        if (id == null) return signedOut(context);
        return _SignedInScope(
          key: ValueKey(id),
          uid: id,
          builder: signedIn,
        );
      },
    );
  }
}

/// Calls [builder] once, when its state is created, and keeps the result. The
/// gate keys it by uid, so repeated events and parent rebuilds reuse the child.
class _SignedInScope extends StatefulWidget {
  const _SignedInScope({super.key, required this.uid, required this.builder});

  final String uid;
  final Widget Function(BuildContext context, String uid) builder;

  @override
  State<_SignedInScope> createState() => _SignedInScopeState();
}

class _SignedInScopeState extends State<_SignedInScope> {
  Widget? _child;

  @override
  Widget build(BuildContext context) {
    return _child ??= widget.builder(context, widget.uid);
  }
}
