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
        return KeyedSubtree(key: ValueKey(id), child: signedIn(context, id));
      },
    );
  }
}
