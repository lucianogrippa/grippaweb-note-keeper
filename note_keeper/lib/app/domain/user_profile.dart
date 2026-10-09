

import 'package:hive_ce/hive.dart';

class UserProfile {
  late String id;
  late String name;
  late String email;

  UserProfile({required this.id, required this.name, required this.email});

  void fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final email = reader.readString();
    return UserProfile(id: id, name: name, email: email);
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.email);
  }
}