

import 'package:hive_ce/hive.dart';

class UserProfile {
  late String id;
  late String name;
  late String lastname;
  late String email;
  late String passwordHash;
  late DateTime createdAt;
  late DateTime lastAccess;
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final lastname = reader.readString();
    final email = reader.readString();
    final passwordHash = reader.readString();
    final createdAt = DateTime.parse(reader.readString());
    final lastAccess = DateTime.parse(reader.readString());
    return UserProfile()
      ..id = id
      ..name = name
      ..lastname = lastname
      ..email = email
      ..passwordHash = passwordHash
      ..createdAt = createdAt
      ..lastAccess = lastAccess;
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.lastname);
    writer.writeString(obj.email);
    writer.writeString(obj.passwordHash);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.lastAccess.toIso8601String());
    }
}