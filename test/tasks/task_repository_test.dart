import 'dart:async';

import 'package:asistente_voz/assistant/command_parser.dart';
import 'package:asistente_voz/tasks/task_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

// Mocking the sealed Firestore types is the only way to simulate a write that
// is never acknowledged.
// ignore_for_file: subtype_of_sealed_class

class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDoc extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() => fake = FakeFirebaseFirestore());

  test('add writes the task under the user and watch returns it', () async {
    final repo = FirestoreTaskRepository(fake, 'u1');
    await repo.add(
      ParsedTask(
        title: 'Pagar el internet',
        heard: 'x',
        dueDate: DateTime(2026, 11, 20),
      ),
    );
    final doc = (await fake.collection('users/u1/tasks').get()).docs.single
        .data();
    expect(
      [doc['title'], doc['done'], doc['dueDate'], doc['heard']],
      ['Pagar el internet', false, '2026-11-20', 'x'],
    );
    final list = await repo.watch().first;
    expect(
      [list.single.title, list.single.dueDate],
      ['Pagar el internet', DateTime(2026, 11, 20)],
    );
    expect(list.single.createdAt, isNotNull);
  });

  test('another user sees nothing', () async {
    await FirestoreTaskRepository(
      fake,
      'u1',
    ).add(const ParsedTask(title: 'Algo', heard: 'algo'));
    expect(await FirestoreTaskRepository(fake, 'u2').watch().first, isEmpty);
  });

  test('a null or odd createdAt stays null', () async {
    await fake.collection('users/u1/tasks').doc('a').set({
      'title': 'A',
      'done': false,
      'createdAt': null,
    });
    await fake.collection('users/u1/tasks').doc('b').set({
      'title': 'B',
      'done': false,
      'createdAt': 'ayer',
    });
    final list = await FirestoreTaskRepository(fake, 'u1').watch().first;
    expect(list.map((t) => t.createdAt), [null, null]);
  });

  test('setDone and delete', () async {
    final repo = FirestoreTaskRepository(fake, 'u1');
    await repo.add(const ParsedTask(title: 'Algo', heard: 'algo'));
    final id = (await repo.watch().first).single.id;
    await repo.setDone(id, true);
    expect((await repo.watch().first).single.done, isTrue);
    await repo.delete(id);
    expect(
      await fake.collection('users/u1/tasks').get().then((s) => s.docs),
      isEmpty,
    );
  });

  test('add gives up when the write is never acknowledged and leaves nothing '
      'behind', () async {
    final firestore = _MockFirestore();
    final collection = _MockCollection();
    final doc = _MockDoc();
    when(() => firestore.collection('users/u1/tasks')).thenReturn(collection);
    when(() => collection.doc()).thenReturn(doc);
    when(() => doc.set(any())).thenAnswer((_) => Completer<void>().future);
    when(() => doc.delete()).thenAnswer((_) async {});

    final repo = FirestoreTaskRepository(
      firestore,
      'u1',
      ackTimeout: const Duration(milliseconds: 50),
    );
    await expectLater(
      repo.add(const ParsedTask(title: 'Algo', heard: 'algo')),
      throwsA(isA<TimeoutException>()),
    );
    verify(() => doc.delete()).called(1);
  });

  test('a failing cleanup after a timeout is swallowed', () async {
    final firestore = _MockFirestore();
    final collection = _MockCollection();
    final doc = _MockDoc();
    when(() => firestore.collection('users/u1/tasks')).thenReturn(collection);
    when(() => collection.doc()).thenReturn(doc);
    when(() => doc.set(any())).thenAnswer((_) => Completer<void>().future);
    when(() => doc.delete())
        .thenAnswer((_) => Future<void>.error(Exception('denied')));

    final repo = FirestoreTaskRepository(
      firestore,
      'u1',
      ackTimeout: const Duration(milliseconds: 50),
    );
    await expectLater(
      repo.add(const ParsedTask(title: 'Algo', heard: 'algo')),
      throwsA(isA<TimeoutException>()),
    );
    // Let the failed cleanup settle; an unhandled error would fail the test.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verify(() => doc.delete()).called(1);
  });
}
