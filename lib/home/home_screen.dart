import 'package:material_ui/material_ui.dart';

import '../tasks/task.dart';
import '../tasks/task_repository.dart';
import '../tasks/tasks_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.tasks, required this.onSignOut});

  final TaskRepository tasks;
  final VoidCallback onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Kept so rebuilds do not subscribe again.
  late final Stream<List<Task>> _stream = widget.tasks.watch();

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
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                  onPressed: widget.onSignOut,
                ),
              ],
              bottom: TabBar(
                tabs: [
                  const Tab(text: 'Asistente'),
                  Tab(text: 'Mis tareas (${pendingCount(tasks)})'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Placeholder until the assistant tab exists.
                const Center(child: Text('El asistente llega pronto.')),
                TasksTab(
                  tasks: tasks,
                  today: DateTime(now.year, now.month, now.day),
                  onToggle: (task, done) =>
                      _run(() => widget.tasks.setDone(task.id, done)),
                  onDelete: (task) => _run(() => widget.tasks.delete(task.id)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
