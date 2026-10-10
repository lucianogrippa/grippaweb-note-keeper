import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:note_keeper/app/services/security_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';
import 'package:path/path.dart' as path show join;
import 'package:path_provider/path_provider.dart';

abstract class IDatabaseService {

  Future<bool> isDbExistsInSystem();

  Future<Box<T>> open<T>({
    String? table,
    required TypeAdapter<T> adapter,
    String? password,
  });

  Future<void> deleteDatabase();

  String hashPassword(String password);
}

class DatabaseService extends IDatabaseService {

  static String _dbPath = "";

  final IStorageService _storageService;

  DatabaseService({required this._storageService});

  @override
  Future<void> deleteDatabase() async {
    if (await isDbExistsInSystem()) {
      try {
        await Hive.close();
      } on Exception catch (e) {
        debugPrint("Error closing database: $e");
      }
      await Directory(_dbPath).delete(recursive: true);
    }
  }

  @override
  Future<bool> isDbExistsInSystem() async {
    if (_dbPath.isEmpty) {
      return false;
    }

    return await Directory(_dbPath).exists();
  }

  @override
  Future<Box<T>> open<T>({
    String? table,
    required TypeAdapter<T> adapter,
    String? password,
  }) async {
    try {
      password = await setupMasterPassword(password);

      if (password == null || password.isEmpty) {
        debugPrint("Failed to setup master password");
        throw ArgumentError("Failed to setup master password");
      }

      final rawKey = _generateEncryptionKey(password);

      final cipher = HiveAesCipher(rawKey);

      table = table ?? T.toString();

      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      } else {
        debugPrint("Adapter for ${adapter.runtimeType} is already registered");
      }

       return await Hive.openBox<T>(table, encryptionCipher: cipher);
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
      throw ArgumentError("Failed to open database: $e");
    }
  }

  Future<String?> setupMasterPassword(String? password) async {
    if (password == null || password.isEmpty) {
      // generate password and store it in master password
      password = await _storageService.loadMasterPassword();

      if (password.isEmpty) {
        password = await _storageService.generateAndStoreMasterPassword();
      }
    }
    return password;
  }

  Future<String> getDatabasesPath() async {
    // get data folder path
    final directory = await getApplicationDocumentsDirectory();
    final fileDbPath = path.join(directory.path, "data");
    return fileDbPath;
  }

  static Future<void> init() async {
    var userDataPath = await getApplicationDocumentsDirectory();

    var basePath = path.join(userDataPath.path,SecurityService.sha256Hex("note_keeper_db"));

    // create folders if not exist
    await Directory(basePath).create(recursive: true);

    await Hive.initFlutter(basePath);

    _dbPath = path.join(basePath);
  }

  List<int> _generateEncryptionKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

  @override
  String hashPassword(String password) {
    if (password.isEmpty) {
      throw ArgumentError("Password cannot be empty");
    }

    var derivedPassword = _storageService.deriveSignKeyFromPassword(password);
    return derivedPassword;
  }
}
