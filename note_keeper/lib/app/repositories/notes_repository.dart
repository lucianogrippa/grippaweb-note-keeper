import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/repositories/base_repository.dart';

import '../services/database_service.dart';

abstract class INoteRepository {

  Future<Notes?> findById(String id);
  Future<Set<Notes>> getAll(String groupId);
  Future<Set<Notes>> searchWithTitleOrContent(String groupId, String title, String content);

  Future<Notes?> decryptContent(String categoryId, String content, String password);
  Future<Notes?> encryptContent(String categoryId, String content, String password);

  Future<Notes?> createNote(Notes note);
  Future<Notes?> updateNote(Notes note);
  Future<bool> deleteNote(String id);

  Future<void> open();

  factory INoteRepository.create(IDatabaseService databaseService) =>
      NoteRepository(databaseService: databaseService);
}


class NoteRepository extends BaseRepository<Notes> implements INoteRepository {

  NoteRepository({required IDatabaseService databaseService}) {
    this.databaseService = databaseService;
  }

  @override
  Future<Notes?> createNote(Notes note) {
    // TODO: implement createNote
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteNote(String id) {
    // TODO: implement deleteNote
    throw UnimplementedError();
  }

  @override
  Future<Notes?> findById(String id) {
    // TODO: implement findById
    throw UnimplementedError();
  }

  @override
  Future<Set<Notes>> getAll(String groupId) {
    // TODO: implement getAll
    throw UnimplementedError();
  }

  @override
  Future<void> open() {
    // TODO: implement open
    throw UnimplementedError();
  }

  @override
  Future<Set<Notes>> searchWithTitleOrContent(String groupId, String title, String content) {
    // TODO: implement searchWithTitleOrContent
    throw UnimplementedError();
  }

  @override
  Future<Notes?> updateNote(Notes note) {
    // TODO: implement updateNote
    throw UnimplementedError();
  }

  @override
  Future<Notes?> decryptContent(String categoryId, String content, String password) {
    // TODO: implement decryptContent
    throw UnimplementedError();
  }

  @override
  Future<Notes?> encryptContent(String categoryId, String content, String password) {
    // TODO: implement encryptContent
    throw UnimplementedError();
  }
}