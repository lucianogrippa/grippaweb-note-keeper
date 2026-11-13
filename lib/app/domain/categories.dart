import 'package:hive_ce/hive.dart';

class NoteCategory {
  late String id;
  late String userId;
  late String name;
  late String description;
  late DateTime createdAt;
  late DateTime updatedAt;
}


class NoteCategoryAdapter extends TypeAdapter<NoteCategory> {

  @override
  final int typeId = 1;

  @override
  NoteCategory read(BinaryReader reader) {

    NoteCategory category = NoteCategory();
    category.id = reader.readString();
    category.userId = reader.readString();
    category.name = reader.readString();
    category.description = reader.readString();
    category.createdAt = DateTime.parse(reader.readString());
    category.updatedAt = DateTime.parse(reader.readString());
    return category;
  }



  @override
  void write(BinaryWriter writer, NoteCategory obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
  }
  
}

