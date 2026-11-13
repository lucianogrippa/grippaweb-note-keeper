import 'package:flutter/cupertino.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';

class NoteGroupsNotifier extends ChangeNotifier {
  late Set<NoteGroups> groupList = {};

  final INoteCategoryRepository _categoryRepo;
  final INoteGroupRepository _groupRepo;

  NoteGroupsNotifier(this._categoryRepo, this._groupRepo);

  Future<void> loadGroups(String categoryId) async {
    groupList = await _groupRepo.getAllGroups(categoryId);
    notifyListeners();
  }

  Future<NoteCategory?> getCategoryById(String categoryId) =>
      _categoryRepo.findById(categoryId);

  Future<NoteGroups?> addGroup(NoteGroups group) async {
    final result = await _groupRepo.createGroup(group);
    if (result != null) await loadGroups(group.categoriesId);
    return result;
  }

  Future<NoteGroups?> updateGroup(NoteGroups group) async {
    final result = await _groupRepo.updateGroup(group);
    if (result != null) await loadGroups(group.categoriesId);
    return result;
  }

  Future<bool> deleteGroup(NoteGroups group) async {
    final result = await _groupRepo.deleteGroup(group.id);
    if (result) await loadGroups(group.categoriesId);
    return result;
  }

  Set<NoteGroups> getGroupsByCategoryId(String categoryId) {
    return groupList.where((group) => group.categoriesId == categoryId).toSet();
  }
}
