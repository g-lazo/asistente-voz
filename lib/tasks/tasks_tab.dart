import 'package:material_ui/material_ui.dart';

import '../theme/noche.dart';
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
    final day = DateTime(today.year, today.month, today.day);
    final pending = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if (pending.isNotEmpty) const _SectionLabel('Pendientes'),
        for (final task in pending) _card(context, task, day, scheme),
        if (done.isNotEmpty) const _SectionLabel('Hechas'),
        for (final task in done) _card(context, task, day, scheme),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    Task task,
    DateTime day,
    ColorScheme scheme,
  ) {
    final due = task.dueDate;
    final overdue = due != null && !task.done && due.isBefore(day);
    final textColor = scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: Noche.panel(radius: 14),
        padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
        child: Row(
          children: [
            Checkbox(
              shape: const CircleBorder(),
              activeColor: Noche.violet,
              checkColor: Colors.white,
              side: const BorderSide(color: Color(0x80FFFFFF), width: 1.5),
              value: task.done,
              onChanged: (v) => onToggle(task, v ?? false),
            ),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: task.done
                      ? textColor.withValues(alpha: 0.5)
                      : textColor,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (due != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: overdue
                      ? scheme.error.withValues(alpha: 0.25)
                      : const Color(0x477C5CFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  chipDateLabel(due, today),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: overdue ? scheme.error : const Color(0xFFD6CCFF),
                  ),
                ),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _confirmDelete(context, task),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Noche.textMuted,
        ),
      ),
    );
  }
}
