import 'package:hive_ce/hive.dart';

class Notes {
  late String id;
  late String groupsId;
  late String title;
  late String content;
  String? description = '';
  late bool isEncrypted;
  late DateTime createdAt;
  late DateTime updatedAt;
}

class NotesAdapter extends TypeAdapter<Notes> {
  @override
  final int typeId = 3;

  @override
  Notes read(BinaryReader reader) {
    Notes note = Notes();
    note.id = reader.readString();
    note.groupsId = reader.readString();
    note.title = reader.readString();
    note.content = reader.readString();
    note.isEncrypted = reader.readBool();
    note.createdAt = DateTime.parse(reader.readString());
    note.updatedAt = DateTime.parse(reader.readString());
    note.description = reader.readString();
    return note;
  }

  @override
  void write(BinaryWriter writer, Notes obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.groupsId);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeBool(obj.isEncrypted);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeString(obj.description ?? '');
  }
}
