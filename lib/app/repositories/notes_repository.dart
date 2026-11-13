import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/repositories/base_repository.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/app/services/security_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';

abstract class INoteRepository {
  Future<Notes?> findById(String id);
  Future<Set<Notes>> getAll(String groupId);
  Future<bool> hasNotes(String groupId);
  Future<Set<Notes>> searchWithTitleOrContent(
    String groupId,
    String title,
    String content,
  );
  Future<String?> revealContent(String id);
  Future<String?> decryptContent(String content);
  Future<String?> encryptContent(String content);
  Future<Notes?> createNote(Notes note);
  Future<Notes?> updateNote(
    Notes note, {
    bool preserveEncryptedContent = false,
  });
  Future<bool> deleteNote(String id);
  Future<void> open();

  factory INoteRepository.create(
    IDatabaseService databaseService,
    IStorageService storageService,
  ) => NoteRepository(
    databaseService: databaseService,
    storageService: storageService,
  );
}

class NoteRepository extends BaseRepository<Notes> implements INoteRepository {
  final IStorageService storageService;

  NoteRepository({
    required IDatabaseService databaseService,
    required this.storageService,
  }) {
    this.databaseService = databaseService;
  }

  Notes _copy(Notes note, {String? content}) => Notes()
    ..id = note.id
    ..groupsId = note.groupsId
    ..title = note.title
    ..content = content ?? note.content
    ..isEncrypted = note.isEncrypted
    ..createdAt = note.createdAt
    ..updatedAt = note.updatedAt;

  Notes _visible(Notes note) =>
      _copy(note, content: note.isEncrypted ? '***' : note.content);

  @override
  Future<bool> hasNotes(String groupId) async =>
      db.values.any((note) => note.groupsId == groupId);

  @override
  Future<Notes?> findById(String id) async {
    final note = db.get(id);
    return note == null ? null : _visible(note);
  }

  @override
  Future<Set<Notes>> getAll(String groupId) async =>
      db.values.where((note) => note.groupsId == groupId).map(_visible).toSet();

  @override
  Future<Set<Notes>> searchWithTitleOrContent(
    String groupId,
    String title,
    String content,
  ) async {
    final titleQuery = title.toLowerCase();
    final contentQuery = content.toLowerCase();
    return db.values
        .where((note) {
          if (note.groupsId != groupId) return false;
          return (titleQuery.isNotEmpty &&
                  note.title.toLowerCase().contains(titleQuery)) ||
              (contentQuery.isNotEmpty &&
                  !note.isEncrypted &&
                  note.content.toLowerCase().contains(contentQuery)) ||
              (titleQuery.isEmpty && contentQuery.isEmpty);
        })
        .map(_visible)
        .toSet();
  }

  @override
  Future<String?> revealContent(String id) async {
    final note = db.get(id);
    if (note == null) return null;
    return note.isEncrypted ? decryptContent(note.content) : note.content;
  }

  @override
  Future<Notes?> createNote(Notes note) async {
    if (note.id.isNotEmpty ||
        note.groupsId.isEmpty ||
        note.title.trim().isEmpty) {
      return null;
    }
    if (db.values.any(
      (row) => row.groupsId == note.groupsId && row.title == note.title,
    )) {
      return null;
    }
    final content = note.isEncrypted
        ? await encryptContent(note.content)
        : note.content;
    if (content == null) return null;
    final now = DateTime.now();
    final stored = Notes()
      ..id = SecurityService.generateUniqueKeySalt()
      ..groupsId = note.groupsId
      ..title = note.title
      ..content = content
      ..isEncrypted = note.isEncrypted
      ..createdAt = now
      ..updatedAt = now;
    await db.put(stored.id, stored);
    return _visible(stored);
  }

  @override
  Future<Notes?> updateNote(
    Notes note, {
    bool preserveEncryptedContent = false,
  }) async {
    if (note.id.isEmpty || note.groupsId.isEmpty || note.title.trim().isEmpty) {
      return null;
    }
    final existing = db.get(note.id);
    if (existing == null || existing.groupsId != note.groupsId) return null;
    if (db.values.any(
      (row) =>
          row.groupsId == note.groupsId &&
          row.title == note.title &&
          row.id != note.id,
    )) {
      return null;
    }
    if (preserveEncryptedContent &&
        (!existing.isEncrypted || !note.isEncrypted)) {
      return null;
    }
    final content = preserveEncryptedContent
        ? existing.content
        : note.isEncrypted
        ? await encryptContent(note.content)
        : note.content;
    if (content == null) return null;
    final stored = Notes()
      ..id = existing.id
      ..groupsId = existing.groupsId
      ..title = note.title
      ..content = content
      ..isEncrypted = note.isEncrypted
      ..createdAt = existing.createdAt
      ..updatedAt = DateTime.now();
    await db.put(stored.id, stored);
    return _visible(stored);
  }

  @override
  Future<bool> deleteNote(String id) async {
    if (id.isEmpty || db.get(id) == null) return false;
    await db.delete(id);
    return true;
  }

  @override
  Future<void> open() async => openDatabase(NotesAdapter(), 'notes');

  @override
  Future<String?> decryptContent(String content) async {
    final masterKey = await storageService.loadMasterPassword();
    if (masterKey.isEmpty) return null;
    if (content.startsWith('v1:')) {
      return SecurityService.decryptNoteContent(content, masterKey);
    }
    final iv = await storageService.loadSaltKey();
    if (iv.isEmpty) return null;
    try {
      return await SecurityService.decryptAESText(content, masterKey, iv);
    } on ArgumentError {
      return null;
    } on Exception {
      return null;
    }
  }

  @override
  Future<String?> encryptContent(String content) async {
    final masterKey = await storageService.loadMasterPassword();
    if (masterKey.isEmpty) return null;
    return SecurityService.encryptNoteContent(content, masterKey);
  }
}
