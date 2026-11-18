import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';
import 'package:note_keeper/app/services/security_service.dart';

class NotesBox implements Box<Notes> {
  final entries = <String, Notes>{};
  @override
  Iterable<Notes> get values => entries.values;
  @override
  Notes? get(dynamic key, {Notes? defaultValue}) =>
      entries[key] ?? defaultValue;
  @override
  Future<void> put(dynamic key, Notes value) async => entries[key] = value;
  @override
  Future<void> delete(dynamic key) async => entries.remove(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class NoteTestStorage implements IStorageService {
  bool available = true;
  @override
  Future<String> loadMasterPassword() async => available
      ? '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
      : '';
  @override
  Future<String> loadSaltKey() async => '123456789012';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class NoteTestDatabase implements IDatabaseService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Notes draft(String title, String content, {bool encrypted = false}) => Notes()
  ..id = ''
  ..groupsId = 'group'
  ..title = title
  ..content = content
  ..isEncrypted = encrypted;

void main() {
  test(
    'note encryption uses fresh nonces and supports legacy ciphertext',
    () async {
      final first = SecurityService.encryptNoteContent('same', 'master key');
      final second = SecurityService.encryptNoteContent('same', 'master key');
      expect(first, isNot(second));
      expect(SecurityService.decryptNoteContent(first, 'master key'), 'same');
      expect(SecurityService.decryptNoteContent(first, 'wrong key'), isNull);
      expect(
        SecurityService.decryptNoteContent('v1:invalid:invalid', 'master key'),
        isNull,
      );
      final legacyStorage = LegacyStorage();
      final repository = NoteRepository(
        databaseService: NoteTestDatabase(),
        storageService: legacyStorage,
      )..db = NotesBox();
      final legacy = await SecurityService.encryptAESText(
        'old',
        await legacyStorage.loadMasterPassword(),
        await legacyStorage.loadSaltKey(),
      );
      expect(await repository.decryptContent(legacy!), 'old');
    },
  );

  test(
    'encrypted reads mask copies and reveal without corrupting storage',
    () async {
      final box = NotesBox();
      final repository = NoteRepository(
        databaseService: NoteTestDatabase(),
        storageService: NoteTestStorage(),
      )..db = box;
      final created = (await repository.createNote(
        draft('Secret', 'private', encrypted: true),
      ))!;
      expect(created.content, '***');
      final ciphertext = box.entries[created.id]!.content;
      expect(ciphertext, isNot('private'));
      expect((await repository.getAll('group')).single.content, '***');
      expect((await repository.findById(created.id))!.content, '***');
      expect(
        (await repository.searchWithTitleOrContent(
          'group',
          'Secret',
          '',
        )).single.content,
        '***',
      );
      created.description = 'Private details';
      await repository.updateNote(created, preserveEncryptedContent: true);
      final descriptionMatches = await repository.searchWithTitleOrContent(
        'group',
        'DETAILS',
        '',
      );
      expect(descriptionMatches.single.description, 'Private details');
      expect(descriptionMatches.single.content, '***');
      expect(await repository.revealContent(created.id), 'private');
      expect(box.entries[created.id]!.content, ciphertext);
      expect(
        await repository.searchWithTitleOrContent('group', '', 'private'),
        isEmpty,
      );

      created.title = 'Renamed';
      await repository.updateNote(created, preserveEncryptedContent: true);
      expect(box.entries[created.id]!.content, ciphertext);
      expect(await repository.revealContent(created.id), 'private');
      created.content = 'changed';
      await repository.updateNote(created);
      expect(await repository.revealContent(created.id), 'changed');
      created.isEncrypted = false;
      created.content = 'plain';
      await repository.updateNote(created);
      expect((await repository.getAll('group')).single.content, 'plain');
      expect(await repository.deleteNote(created.id), isTrue);
      expect(await repository.getAll('group'), isEmpty);
    },
  );

  test('encryption failures do not replace the original note', () async {
    final storage = NoteTestStorage();
    final box = NotesBox();
    final repository = NoteRepository(
      databaseService: NoteTestDatabase(),
      storageService: storage,
    )..db = box;
    final created = (await repository.createNote(
      draft('Secret', 'private', encrypted: true),
    ))!;
    final stored = box.entries[created.id]!.content;
    storage.available = false;
    expect(await repository.revealContent(created.id), isNull);
    created.content = 'replacement';
    expect(await repository.updateNote(created), isNull);
    expect(box.entries[created.id]!.content, stored);
    expect(
      await repository.createNote(draft('New', 'text', encrypted: true)),
      isNull,
    );
    expect(box.entries, hasLength(1));
  });
}

class LegacyStorage extends NoteTestStorage {
  @override
  Future<String> loadMasterPassword() async =>
      '12345678901234567890123456789012';
}
