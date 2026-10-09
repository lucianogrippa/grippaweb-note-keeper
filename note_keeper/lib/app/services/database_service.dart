import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:path/path.dart' as path show join;
import 'package:path_provider/path_provider.dart';

abstract class IDatabaseService{

  Box? dataSource();

  Future<bool> isDbExistsInSystem();
  Future<bool> open<T, A>({String? table, required String password});

  Future<void> init();
  Future<void> deleteDatabase();
}

class DatabaseService extends IDatabaseService {

  late String _dbPath;
  late Box? db;


  @override
  Future<void> deleteDatabase() async {
    if (await isDbExistsInSystem()) {
      try {
        await db?.close();
      } on Exception catch (e) {
        debugPrint("Error closing database: $e");
      }
      await File(_dbPath).delete();
    }
  }

  @override
  Future<bool> isDbExistsInSystem() async {

    if(_dbPath.isEmpty) {
      return false;
    }

    return await File(_dbPath).exists();
  }

  DatabaseService();

@override
Future<bool> open<T, A>({String? table, required String   password}) async {

    try {
      if(password.isEmpty) {
        return false;
      }

      final rawKey = _generateEncryptionKey(password);

      final cipher = HiveAesCipher(rawKey);

      table = table ?? T.toString();

      if(Hive.isAdapterRegistered((A as TypeAdapter<T>).typeId)) {
        debugPrint("Adapter for ${A.toString()} is already registered");
      } else {
        debugPrint("Registering adapter for ${A.toString()}");
      }

      Hive.registerAdapter(A as TypeAdapter<T>);

      db =  await Hive.openBox<T>(table,encryptionCipher: cipher);

        // onCreate: (db, version) async {
        //
        //   /// create user profile
        //   await db.execute('''
        //  CREATE TABLE IF NOT EXISTS user_profile (
        //       id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        //       username TEXT NOT NULL,
        //       name TEXT NOT NULL,
        //       lastname TEXT NOT NULL,
        //       email TEXT NOT NULL,
        //       password_hash TEXT NOT NULL,
        //       created_at TEXT NOT NULL,
        //       updated_at TEXT NOT NULL
        //   )
        // ''');
        //
        //   /// categories
        //   await db.execute('''
        //  CREATE TABLE IF NOT EXISTS categories (
        //             id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        //             user_id TEXT NOT NULL,
        //             name TEXT NOT NULL,
        //             description TEXT,
        //             created_at TEXT NOT NULL,
        //             updated_at TEXT NOT NULL,
        //             FOREIGN KEY (user_id) REFERENCES user_profile(id)
        //         )
        // ''');
        //
        //   /// groups
        //   await db.execute('''
        // CREATE TABLE IF NOT EXISTS groups (
        //         id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        //         categories_id TEXT NOT NULL,
        //         name TEXT NOT NULL,
        //         created_at TEXT NOT NULL,
        //         updated_at TEXT NOT NULL,
        //         FOREIGN KEY (categories_id) REFERENCES categories(id)
        //     )
        // ''');
        //
        //
        //   /// notes
        //   await db.execute('''
        // CREATE TABLE IF NOT EXISTS notes (
        //       id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        //       groups_id TEXT NOT NULL,
        //       title TEXT NOT NULL,
        //       content TEXT NOT NULL,
        //       is_encrypted INTEGER NOT NULL DEFAULT 0,
        //       created_at TEXT NOT NULL,
        //       updated_at TEXT NOT NULL,
        //       FOREIGN KEY (groups_id) REFERENCES groups(id)
        //     )
        // ''');
        // }
    } on Exception catch (e) {
      debugPrint("Error opening database: $e");
      return false;
    }

    return db?.isOpen ?? false;
  }

  factory DatabaseService.createWithPassword(String password)  => DatabaseService()..open(password: password);
  factory DatabaseService.create() =>  DatabaseService();
  @override
  Box? dataSource() {
    return db;
  }

  Future<String> getDatabasesPath() async {
    // get data folder path
    final directory = await getApplicationDocumentsDirectory();
    final fileDbPath = path.join(directory.path, "data");
    return fileDbPath;
  }

  List<int> _generateEncryptionKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.bytes; // Genera esattamente 32 byte (256 bit)
  }

  @override
  Future<void> init() async {
    var userDataPath = await getApplicationDocumentsDirectory();

    var basePath = path.join(userDataPath.path, "note-keeper");

    // create folders if not exist
    await Directory(basePath).create(recursive: true);

    await Hive.initFlutter(basePath);

    _dbPath = path.join(basePath);
  }
}