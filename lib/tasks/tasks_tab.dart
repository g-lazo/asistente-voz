import 'package:material_ui/material_ui.dart';

import 'date_label.dart';
import 'task.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({
    super.key,
    required this.tasks,
    required this.today,
    required this.onToggle,
    required this.onDelete,
  });

  /// Already sorted.
  final List<Task> tasks;
  final DateTime today;
  final void Function(Task task, bool done) onToggle;
  final void Function(Task task) onDelete;

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete(task);
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no tienes tareas. Ve al Asistente y dicta la primera.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        final due = task.dueDate;
        final overdue = due != null && !task.done && due.isBefore(today);
        return ListTile(
          leading: Checkbox(
            value: task.done,
            onChanged: (v) => onToggle(task, v ?? false),
          ),
          title: Text(
            task.title,
            style: task.done
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: due == null
              ? null
              : Text(
                  shortDateLabel(due),
                  style: overdue ? TextStyle(color: scheme.error) : null,
                ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: () => _confirmDelete(context, task),
          ),
        );
      },
    );
  }
}
