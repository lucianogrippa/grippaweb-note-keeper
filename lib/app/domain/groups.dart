import 'package:hive_ce/hive.dart';

class NoteGroups {
  late String id;
  late String categoriesId;
  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;
}


class NoteGroupsAdapter extends TypeAdapter<NoteGroups> {

  @override
  final int typeId = 2;

  @override
  NoteGroups read(BinaryReader reader) {
    NoteGroups group = NoteGroups();
    group.id = reader.readString();
    group.categoriesId = reader.readString();
    group.name = reader.readString();
    group.createdAt = DateTime.parse(reader.readString());
    group.updatedAt = DateTime.parse(reader.readString());
    return group;
  }

  @override
  void write(BinaryWriter writer, NoteGroups obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.categoriesId);
    writer.writeString(obj.name);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
  }
}