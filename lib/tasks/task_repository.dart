import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../assistant/command_parser.dart';
import 'task.dart';

abstract class TaskRepository {
  /// Live, unsorted.
  Stream<List<Task>> watch();

  /// Completes once the server accepted the write. Throws if it fails or
  /// takes more than the repository's ack timeout.
  Future<void> add(ParsedTask task);

  Future<void> setDone(String id, bool done);

  Future<void> delete(String id);
}

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(
    FirebaseFirestore firestore,
    String uid, {
    this.ackTimeout = const Duration(seconds: 10),
  }) : _tasks = firestore.collection('users/$uid/tasks');

  final CollectionReference<Map<String, dynamic>> _tasks;
  final Duration ackTimeout;

  @override
  Stream<List<Task>> watch() => _tasks.snapshots().map(
    (snapshot) => [
      for (final doc in snapshot.docs)
        Task.fromMap(doc.id, _decode(doc.data())),
    ],
  );

  /// Firestore's Timestamp becomes a DateTime; null (write not acknowledged
  /// yet) or any other type stays null.
  Map<String, dynamic> _decode(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return {
      ...data,
      'createdAt': createdAt is Timestamp ? createdAt.toDate() : null,
    };
  }

  @override
  Future<void> add(ParsedTask task) async {
    final ref = _tasks.doc();
    try {
      await ref
          .set({
            'title': task.title,
            'done': false,
            'dueDate': encodeDueDate(task.dueDate),
            'heard': task.heard,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(ackTimeout);
    } on TimeoutException {
      // The write is queued locally; remove it so it cannot surface later.
      unawaited(ref.delete());
      rethrow;
    }
  }

  @override
  Future<void> setDone(String id, bool done) =>
      _tasks.doc(id).update({'done': done});

  @override
  Future<void> delete(String id) => _tasks.doc(id).delete();
}
