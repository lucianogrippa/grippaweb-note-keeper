import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/repositories/base_repository.dart';

import '../services/database_service.dart';
import '../services/security_service.dart';

abstract class INoteGroupRepository {
  Future<Set<NoteGroups>> getAllGroups(String categoryId);
  Future<Set<NoteGroups>> searchWithName(String categoryId, String name);
  Future<NoteGroups?> getGroupById(String id);

  Future<NoteGroups?> createGroup(NoteGroups group);
  Future<NoteGroups?> updateGroup(NoteGroups group);
  Future<bool> deleteGroup(String id);

  Future<void> open();

  factory INoteGroupRepository.create(IDatabaseService databaseService) =>
      NoteGroupRepository(databaseService: databaseService);
}

class NoteGroupRepository extends BaseRepository<NoteGroups> implements INoteGroupRepository {

  NoteGroupRepository({required IDatabaseService databaseService}) {
    this.databaseService = databaseService;
  }

  @override
  Future<Set<NoteGroups>> getAllGroups(String categoryId) async {
    return db.values.where((row) => row.categoriesId == categoryId).toSet();
  }

  @override
  Future<Set<NoteGroups>> searchWithName(String categoryId, String name) async {
    return db.values
        .where((row) =>
            row.categoriesId == categoryId &&
            row.name.toLowerCase().contains(name.toLowerCase()))
        .toSet();
  }

  @override
  Future<NoteGroups?> getGroupById(String id) async {
    return db.get(id);
  }

  @override
  Future<NoteGroups?> createGroup(NoteGroups group) async {

    if(group.id != '' || group.name == '' || group.categoriesId == '') {
      return null;
    }

    group.id = SecurityService.generateUniqueKeySalt();

    group.createdAt = DateTime.now();

    await db.put(group.id, group);
    return group;
  }

  @override
  Future<NoteGroups?> updateGroup(NoteGroups group) async {

    if(group.id == '' || group.name == '' || group.categoriesId == '') {
      return null;
    }

    await db.put(group.id, group);

    return group;
  }

  @override
  Future<bool> deleteGroup(String id) async {

    if(id == ''){
      return false;
    }

    await db.delete(id);
    return true;
  }

  @override
  Future<void> open() async {
    await super.openDatabase(NoteGroupsAdapter(), 'note_groups');
  }


}