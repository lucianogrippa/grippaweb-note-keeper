import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';

class FakeBox<T> implements Box<T> {
  final entries = <dynamic, T>{};

  @override
  Iterable<T> get values => entries.values;

  @override
  Future<void> put(dynamic key, T value) async {
    entries[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDatabase implements IDatabaseService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStorage implements IStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('created and updated groups have persistent timestamps', () async {
    final box = FakeBox<NoteGroups>();
    final repository = NoteGroupRepository(databaseService: FakeDatabase())
      ..db = box;
    final group = NoteGroups()
      ..id = ''
      ..categoriesId = 'category'
      ..name = 'Group';

    await repository.createGroup(group);
    expect(group.createdAt, group.updatedAt);
    expect(box.entries[group.id], same(group));

    final oldTimestamp = DateTime(2000);
    group.updatedAt = oldTimestamp;
    await repository.updateGroup(group);
    expect(group.updatedAt.isAfter(oldTimestamp), isTrue);
    expect(box.entries[group.id], same(group));
  });

  test('checking for notes does not mutate encrypted content', () async {
    final box = FakeBox<Notes>();
    final note = Notes()
      ..groupsId = 'group'
      ..isEncrypted = true
      ..content = 'encrypted';
    box.entries['note'] = note;
    final repository = NoteRepository(
      databaseService: FakeDatabase(),
      storageService: FakeStorage(),
    )..db = box;

    expect(await repository.hasNotes('group'), isTrue);
    expect(await repository.hasNotes('other'), isFalse);
    expect(note.content, 'encrypted');
  });
}
