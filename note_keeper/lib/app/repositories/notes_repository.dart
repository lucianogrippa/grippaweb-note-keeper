import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/repositories/base_repository.dart';
import 'package:note_keeper/app/services/storage_service.dart';

import '../services/database_service.dart';
import '../services/security_service.dart';


abstract class INoteRepository {

  Future<Notes?> findById(String id);
  Future<Set<Notes>> getAll(String groupId);
  Future<Set<Notes>> searchWithTitleOrContent(String groupId, String title, String content);

  Future<String?> decryptContent(String content);
  Future<String?> encryptContent(String content);

  Future<Notes?> createNote(Notes note);
  Future<Notes?> updateNote(Notes note);
  Future<bool> deleteNote(String id);

  Future<void> open();

  factory INoteRepository.create(IDatabaseService databaseService, IStorageService storageService) =>
      NoteRepository(databaseService: databaseService, storageService: storageService);
}


class NoteRepository extends BaseRepository<Notes> implements INoteRepository {

  late final IStorageService storageService;

  NoteRepository({required IDatabaseService databaseService, required this.storageService}) {
    this.databaseService = databaseService;
  }

  @override
  Future<Notes?> createNote(Notes note) async {
    // check if note already exists by title and the groupId is required
    if (note.id != '' || note.groupsId == '') {
      return null;
    }

    // check if title exists
    var title = db.values
        .where(
          (row) => row.title == note.title && row.groupsId == note.groupsId,
        )
        .firstOrNull;

    if (title != null) {
      // title already exists
      return null;
    }

    final uniqueId = SecurityService.generateUniqueKeySalt();

    note.id = uniqueId;

    if(note.isEncrypted){
      note.content = (await encryptContent(note.content)) ?? '';

      if(note.content == ''){
        return null;
      }
    }

    note.createdAt = DateTime.now();
    note.updatedAt = DateTime.now();

    db.put(note.id, note);

    return note;
  }

  @override
  Future<bool> deleteNote(String id) async {
    if (id == '') {
      return false;
    }

    var note = db.get(id);

    if (note == null) {
      return false;
    }

    db.delete(id);

    return true;
  }

  @override
  Future<Notes?> findById(String id) async {
    if (id == '') {
      return null;
    }

    var note = db.get(id);

    if (note == null) {
      return null;
    }

    // mask notes if encrypted
    if(note.isEncrypted){
      note.content = '***';
    }

    return note;
  }

  @override
  Future<Set<Notes>> getAll(String groupId) async {
    var notes = db.values.where((note) => note.groupsId == groupId).toSet();

    // mask notes if encrypted
    for (var note in notes) {
      if (note.isEncrypted) {
        note.content = '***';
      }
    }

    return notes;
  }

  @override
  Future<void> open() async {
    await super.openDatabase(NotesAdapter(), 'notes');
  }

  @override
  Future<Set<Notes>> searchWithTitleOrContent(String groupId, String title, String content) async {
    var notes = db.values
        .where((note) =>
            note.groupsId == groupId &&
            (note.title.toLowerCase().contains(title.toLowerCase()) ||
                note.content.toLowerCase().contains(content.toLowerCase())))
        .toSet();

    // mask notes if encrypted
    for (var note in notes) {
      if (note.isEncrypted) {
        note.content = '***';
      }
    }

    return notes;
  }

  @override
  Future<Notes?> updateNote(Notes note) async {
    if (note.id == '' || note.groupsId == '') {
      return null;
    }

    var existingNote = db.get(note.id);

    if (existingNote == null) {
      return null;
    }

    // check if title exists for other notes in the same group
    var title = db.values
        .where(
          (row) =>
              row.title == note.title &&
              row.groupsId == note.groupsId &&
              row.id != note.id,
        )
        .firstOrNull;

    if (title != null) {
      // title already exists
      return null;
    }

    if(note.isEncrypted){
      note.content = (await encryptContent(note.content)) ?? '';

      if(note.content == ''){
        return null;
      }
    }

    note.updatedAt = DateTime.now();

    db.put(note.id, note);

    return note;
  }

  @override
  Future<String?> decryptContent( String content) async {


    // use master key to decrypt content
    var masterKey = await storageService.loadMasterPassword();
    var iv = await storageService.loadSaltKey();

    if(masterKey == '' || iv == ''){
      return null;
    }

    String? decryptedContent = await SecurityService.decryptAESText(content, masterKey, iv);

    return decryptedContent;
  }

  @override
  Future<String?> encryptContent(String content) async {
    // use master key to encrypt content
    var masterKey = await storageService.loadMasterPassword();
    var iv = await storageService.loadSaltKey();

    if(masterKey == '' || iv == ''){
      return null;
    }

    String? encryptedContent = await SecurityService.encryptAESText(content, masterKey, iv);

    return encryptedContent;
  }
}