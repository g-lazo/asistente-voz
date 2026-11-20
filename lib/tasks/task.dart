/// A task as stored in Firestore and shown in the list.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.done,
    required this.heard,
    this.dueDate,
    this.createdAt,
  });

  final String id;
  final String title;
  final bool done;
  final String heard;
  final DateTime? dueDate;
  final DateTime? createdAt;

  /// data['createdAt'] is a DateTime or null; the repository converts
  /// Firestore's Timestamp first. Never throws: a field of the wrong type
  /// reads as its default, so one malformed document does not break the list.
  factory Task.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return Task(
      id: id,
      title: _asString(data['title']),
      done: data['done'] == true,
      heard: _asString(data['heard']),
      dueDate: decodeDueDate(data['dueDate']),
      createdAt: createdAt is DateTime ? createdAt : null,
    );
  }
}

String _asString(Object? v) => v is String ? v : '';

/// "2026-11-20", or null when there is no date.
String? encodeDueDate(DateTime? d) {
  if (d == null) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

final _dueDatePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Anything that is not a valid "YYYY-MM-DD" string gives null.
DateTime? decodeDueDate(Object? raw) {
  if (raw is! String) return null;
  final m = _dueDatePattern.firstMatch(raw);
  if (m == null) return null;
  final y = int.parse(m[1]!);
  final mo = int.parse(m[2]!);
  final d = int.parse(m[3]!);
  final date = DateTime(y, mo, d);
  // DateTime rolls over impossible dates (2026-02-30 -> March 2); reject them.
  if (date.year != y || date.month != mo || date.day != d) return null;
  return date;
}

/// Pending before done. Pending: dated first by due date ascending, then by
/// createdAt descending (null counts as newest). Done: createdAt descending.
List<Task> sortTasks(List<Task> tasks) {
  int newestFirst(Task a, Task b) {
    final x = a.createdAt, y = b.createdAt;
    if (x == null && y == null) return 0;
    if (x == null) return -1;
    if (y == null) return 1;
    return y.compareTo(x);
  }

  int compare(Task a, Task b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    if (!a.done) {
      final x = a.dueDate, y = b.dueDate;
      if (x != null && y == null) return -1;
      if (x == null && y != null) return 1;
      if (x != null && y != null) {
        final c = x.compareTo(y);
        if (c != 0) return c;
      }
    }
    final c = newestFirst(a, b);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  return [...tasks]..sort(compare);
}

int pendingCount(List<Task> tasks) => tasks.where((t) => !t.done).length;
