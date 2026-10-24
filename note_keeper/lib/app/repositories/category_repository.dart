import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/repositories/base_repository.dart';
import 'package:note_keeper/app/services/database_service.dart';

import '../services/security_service.dart';

abstract class INoteCategoryRepository {
  Future<NoteCategory?> findById(String id);

  Future<Set<NoteCategory>> findByUserId(String userId);

  Future<Set<NoteCategory>> searchWithDescriptionOrName(
    String userId,
    String description,
    String name,
  );

  Future<NoteCategory?> add(NoteCategory category);

  Future<NoteCategory?> edit(NoteCategory category);

  Future<bool> delete(String id);

  Future<void> open();

  factory INoteCategoryRepository.create(IDatabaseService databaseService) =>
      NoteCategoryRepository(databaseService: databaseService);
}

class NoteCategoryRepository extends BaseRepository<NoteCategory>
    implements INoteCategoryRepository {
  NoteCategoryRepository({required IDatabaseService databaseService}) {
    this.databaseService = databaseService;
  }

  @override
  Future<NoteCategory?> add(NoteCategory category) async {
    // check if category already exists by name and the userId is required
    if (category.id != '' || category.userId == '') {
      return null;
    }

    // check if name exists
    var name = db.values
        .where(
          (row) => row.name == category.name && row.userId == category.userId,
        )
        .firstOrNull;

    if (name != null) {
      // name already exists
      return null;
    }

    final uniqueId = SecurityService.generateUniqueKeySalt();

    category.id = uniqueId;

    category.createdAt = DateTime.now();
    category.updatedAt = DateTime.now();

    await db.put(category.id, category);
    return category;
  }

  @override
  Future<bool> delete(String id) async {
    if (id == '') {
      return false;
    }

    var category = db.get(id);

    if (category == null) {
      return false;
    }

    await db.delete(id);
    return true;
  }

  @override
  Future<NoteCategory?> edit(NoteCategory category) async {
    if (category.id == '') {
      return null;
    }

    var existingCategory = db.get(category.id);

    if (existingCategory == null) {
      return null;
    }

    category.updatedAt = DateTime.now();

    await db.put(category.id, category);
    return category;
  }

  @override
  Future<NoteCategory?> findById(String id) async {
    if (id == '') {
      return null;
    }

    var category = db.get(id);

    if (category == null) {
      return null;
    }

    return category;
  }

  @override
  Future<Set<NoteCategory>> findByUserId(String userId) async {
    if (userId == '') {
      return {};
    }

    var categories = db.values.where((row) => row.userId == userId).toSet();

    return categories;
  }

  @override
  Future<Set<NoteCategory>> searchWithDescriptionOrName(
    String userId,
    String description,
    String name,
  ) async {
    if (userId == '') {
      return {};
    }

    var categories = db.values
        .where(
          (row) =>
              row.userId == userId &&
              (row.name.contains(name) ||
                  row.description.contains(description)),
        )
        .toSet();

    return categories;
  }

  @override
  Future<void> open() async {
    await super.openDatabase(NoteCategoryAdapter(), 'note_category');
  }
}
