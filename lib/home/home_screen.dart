import 'package:material_ui/material_ui.dart';

import '../assistant/assistant_controller.dart';
import '../assistant/assistant_tab.dart';
import '../assistant/mute_setting.dart';
import '../assistant/speech_input.dart';
import '../assistant/voice_output.dart';
import '../tasks/task.dart';
import '../tasks/task_repository.dart';
import '../tasks/tasks_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.tasks,
    required this.onSignOut,
    required this.speech,
    required this.voice,
    required this.mute,
  });

  final TaskRepository tasks;
  final VoidCallback onSignOut;
  final SpeechInput speech;
  final VoiceOutput voice;
  final MuteSetting mute;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Kept so rebuilds do not subscribe again.
  late final Stream<List<Task>> _stream = widget.tasks.watch();

  // Owned here so the chat survives switching tabs.
  late final AssistantController _assistant;

  @override
  void initState() {
    super.initState();
    _assistant = AssistantController(
      speech: widget.speech,
      voice: widget.voice,
      tasks: widget.tasks,
      muted: widget.mute,
    );
  }

  @override
  void dispose() {
    _assistant.dispose();
    super.dispose();
  }

  /// Write errors must not escape as unhandled async errors.
  Future<void> _run(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar. Inténtalo otra vez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: _stream,
      builder: (context, snapshot) {
        final tasks = sortTasks(snapshot.data ?? const []);
        final now = DateTime.now();
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Asistente de tareas'),
              actions: [
                ValueListenableBuilder<bool>(
                  valueListenable: widget.mute,
                  builder: (context, muted, _) => IconButton(
                    icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
                    tooltip: muted ? 'Activar voz' : 'Silenciar voz',
                    onPressed: widget.mute.toggle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                  onPressed: widget.onSignOut,
                ),
              ],
              bottom: TabBar(
                tabs: [
                  const Tab(text: 'Asistente'),
                  Tab(
                    text: snapshot.hasError
                        ? 'Mis tareas'
                        : 'Mis tareas (${pendingCount(tasks)})',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                AssistantTab(controller: _assistant),
                if (snapshot.hasError)
                  const Center(
                    child: Text(
                      'No se pudieron cargar tus tareas. Revisa tu conexión.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  TasksTab(
                    tasks: tasks,
                    today: DateTime(now.year, now.month, now.day),
                    onToggle: (task, done) =>
                        _run(() => widget.tasks.setDone(task.id, done)),
                    onDelete: (task) =>
                        _run(() => widget.tasks.delete(task.id)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
