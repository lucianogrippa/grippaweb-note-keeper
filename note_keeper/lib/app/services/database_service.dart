import 'dart:io';

import 'package:note_keeper/app/services/security_service.dart';
import 'package:path/path.dart' as path show join;
import 'package:sqflite_sqlcipher/sqflite.dart';

abstract class IDatabaseService{

  Database dataSource();

  Future<bool> isDbExistsInSystem();
  Future<bool> open({String? dbpath, required String password});

  Future<void> deleteDatabase();
}

class DatabaseService extends IDatabaseService {

  final _dbName = "${SecurityService.sha256Hex("note-keeper")}.db";
  late String _dbPath;
  final int _version = 1;
  late Database db;

  @override
  Future<void> deleteDatabase() async {
    if (await isDbExistsInSystem()) {
      try {
        await db.close();
      } on Exception catch (e) {
        print("Error closing database: $e");
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
Future<bool> open({String? dbpath, required String   password}) async {

    if(password.isEmpty) {
      return false;
    }

    var userDataPath = dbpath ?? await getDatabasesPath();

    var basePath = path.join(userDataPath, "note-keeper");

    // create folders if not exist
    await Directory(basePath).create(recursive: true);

    _dbPath = path.join(basePath, _dbName);

    db = await openDatabase(_dbPath,
                  version: _version,
                  password: password,

      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');

      },

      onCreate: (db, version) async {

        /// create user profile
        await db.execute('''
         CREATE TABLE IF NOT EXISTS user_profile (
              id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
              username TEXT NOT NULL,
              name TEXT NOT NULL,
              lastname TEXT NOT NULL,
              email TEXT NOT NULL,
              password_hash TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
          )
        ''');

        /// categories
        await db.execute('''
         CREATE TABLE IF NOT EXISTS categories (
                    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                    user_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    description TEXT,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES user_profile(id)
                )
        ''');

        /// groups
        await db.execute('''
        CREATE TABLE IF NOT EXISTS groups (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                categories_id TEXT NOT NULL,
                name TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (categories_id) REFERENCES categories(id)
            )
        ''');


        /// notes
        await db.execute('''
        CREATE TABLE IF NOT EXISTS notes (
              id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
              groups_id TEXT NOT NULL,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              is_encrypted INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (groups_id) REFERENCES groups(id)
            )
        ''');
      }



    );

    _dbPath = userDataPath;

    return db.isOpen;
  }

  factory DatabaseService.createWithPassword(String password)  => DatabaseService()..open(password: password);

  @override
  Database dataSource() {
    return db;
  }

}