import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'assistant/mute_setting.dart';
import 'assistant/speech_input.dart';
import 'assistant/voice_output.dart';
import 'auth/auth_service.dart';
import 'auth/sign_in_screen.dart';
import 'firebase_options.dart';
import 'home/home_screen.dart';
import 'tasks/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();

  final auth = AuthService(FirebaseAuth.instance);
  // Created once: TtsVoiceOutput prepares the Spanish voice in its constructor.
  final speech = SttSpeechInput();
  final voice = TtsVoiceOutput();
  final mute = MuteSetting(prefs);

  runApp(
    MaterialApp(
      title: 'Asistente de tareas',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B6FD8),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthGate(
        uid: auth.userChanges.map((u) => u?.uid),
        signedOut: (_) => SignInScreen(
          onSignIn: auth.signIn,
          onSignUp: auth.signUp,
        ),
        signedIn: (_, uid) => HomeScreen(
          tasks: FirestoreTaskRepository(FirebaseFirestore.instance, uid),
          onSignOut: auth.signOut,
          speech: speech,
          voice: voice,
          mute: mute,
        ),
      ),
    ),
  );
}
