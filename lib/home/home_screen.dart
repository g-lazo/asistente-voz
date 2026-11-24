import 'package:material_ui/material_ui.dart';

import '../assistant/assistant_controller.dart';
import '../assistant/assistant_tab.dart';
import '../assistant/mute_setting.dart';
import '../assistant/speech_input.dart';
import '../assistant/voice_output.dart';
import '../tasks/date_label.dart';
import '../tasks/task.dart';
import '../tasks/task_repository.dart';
import '../tasks/tasks_tab.dart';
import '../theme/noche.dart';

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
            body: NocheBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    _Header(
                      mute: widget.mute,
                      onSignOut: widget.onSignOut,
                      date: headerDateLabel(now),
                    ),
                    _PillTabs(
                      second: snapshot.hasError
                          ? 'Mis tareas'
                          : 'Mis tareas (${pendingCount(tasks)})',
                    ),
                    Expanded(
                      child: TabBarView(
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
                              onToggle: (task, done) => _run(
                                () => widget.tasks.setDone(task.id, done),
                              ),
                              onDelete: (task) =>
                                  _run(() => widget.tasks.delete(task.id)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mute,
    required this.onSignOut,
    required this.date,
  });

  final MuteSetting mute;
  final VoidCallback onSignOut;
  final String date;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente de tareas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: Noche.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: Noche.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<bool>(
            valueListenable: mute,
            builder: (context, muted, _) => _RoundButton(
              icon: muted ? Icons.volume_off : Icons.volume_up,
              tooltip: muted ? 'Activar voz' : 'Silenciar voz',
              onPressed: mute.toggle,
            ),
          ),
          const SizedBox(width: 8),
          _RoundButton(
            icon: Icons.logout,
            tooltip: 'Cerrar sesión',
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x1AFFFFFF),
        foregroundColor: Noche.text,
        fixedSize: const Size(44, 44),
      ),
    );
  }
}

/// The tab bar as pills on a panel track. Colours are set here so the bar
/// reads the same without the app theme installed.
class _PillTabs extends StatelessWidget {
  const _PillTabs({required this.second});

  final String second;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: Noche.panel(radius: 14),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Noche.text,
            unselectedLabelColor: Noche.textMuted,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            labelPadding: EdgeInsets.zero,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            indicator: BoxDecoration(
              color: const Color(0x2EFFFFFF),
              borderRadius: BorderRadius.circular(11),
            ),
            tabs: [
              const Tab(height: 38, text: 'Asistente'),
              Tab(height: 38, text: second),
            ],
          ),
        ),
      ),
    );
  }
}
