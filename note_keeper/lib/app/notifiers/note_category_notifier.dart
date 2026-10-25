import 'package:flutter/cupertino.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';

class NoteCategoryNotifier extends ChangeNotifier {
  final INoteCategoryRepository _categoryRepo;

  late Set<NoteCategory> categoryList = {};

  NoteCategoryNotifier(this._categoryRepo);

  Future<void> loadCategories(String userId) async {
    categoryList = await _categoryRepo.findByUserId(userId);
    notifyListeners();
  }

  Future<NoteCategory?> addCategory(NoteCategory category) async {
    var cat = await _categoryRepo.add(category);
    loadCategories(category.userId);
    return cat;
  }

  Future<void> deleteCategory(NoteCategory category) async {
    await _categoryRepo.delete(category.id);
    loadCategories(category.userId);
  }

  Future<void> updateCategory(NoteCategory category) async {
    await _categoryRepo.edit(category);
    loadCategories(category.userId);
  }
}
