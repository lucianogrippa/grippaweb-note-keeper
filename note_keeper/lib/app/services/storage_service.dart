import 'dart:async';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:note_keeper/app/domain/storage_state.dart';
import 'package:note_keeper/app/services/security_service.dart';

abstract class IStorageService {

  // ignore: unused_field
  late final SecurityService _securityService;

  FutureOr<StorageState> build();


  Future<String> loadSaltKey();

  Future<String> loadStoredAuthToken();

  Future<String> loadMasterPassword();

  Future<bool> isMasterPasswordExists();

  Future<void> storeMasterPassword(String password);

  Future<void> storeAuthToken(String username, String name, String scope,
      DateTime expirationTime, String signKey);

  String deriveSignKeyFromPassword(String password);

  Future<void> removeAuthToken();

  String deriveSignKeyFromHashedPassword(String hashedPassword);

  Future<void> removeMasterPassword();

}

class StorageService  implements IStorageService {

  @override
  late final SecurityService _securityService;

  late final FlutterSecureStorage _storage;

  @override
  Future<String> loadSaltKey() async {
    return await _storage.read(key: _saltKey) ?? '';
  }

  @override
  Future<bool> isMasterPasswordExists() async {
    final masterPassword = await _storage.read(key: _masterPwdKey);
    return masterPassword != null && masterPassword.isNotEmpty;
  }

  static const String _authTokenKey ='0aab846a443ddcfe7655696b97d3d5bfc0fb3e98';

  static const String _saltKey = 'bb803d641700e7650059573004929cd1d2dd4e7a';

  static const String _masterPwdKey = 'c3f0e1b8d5a4e7f9b2c1d3a4e5f6b7c8d9e0f1a2';

  @override
  /// Build Storage Service with its dependencies and initial state
  FutureOr<StorageState> build() async {

    /// create secure storage instance with platform specific options
    _storage = FlutterSecureStorage(
      webOptions: WebOptions(
        dbName: 'note_keeper_storage_db',
      ),
      aOptions: AndroidOptions.biometric(
        biometricPromptTitle: 'Secure Note keeper',
        requireBiometricsPerOperation: false,
      ),
      lOptions: LinuxOptions.defaultOptions,
    );

    /// read salt value from secure storage
    final saltValue = await _storage.read(key: _saltKey) ?? '';

    // if salt value is empty, generate a new salt and store it in secure storage,
    // otherwise use the existing salt value
    _securityService = saltValue.isEmpty
        ? SecurityService.initV13Salt()
        : SecurityService.initV13FixedSalt(saltValue);

    if (saltValue.isEmpty) {

      // store the generated salt value in secure storage
      await _storage.write(
        key: _saltKey,
        value: _securityService.currentSalt,
      );
    }

    // load auth token
    final authToken = await loadStoredAuthToken();

    return StorageState()
      ..hasAuthToken = authToken.isNotEmpty;
  }

  /// Load Stored Auth Token from secure storage
  @override
  Future<String> loadStoredAuthToken() async {
    return await _storage.read(key: _authTokenKey) ?? '';
  }

  /// Store Auth Token in secure storage
  @override
  Future<void> storeAuthToken(
      String username,
      String name,
      String scope,
      DateTime expirationTime,
      String signKey) async {

    final secret =
        '$username|${expirationTime.toIso8601String()}|$signKey';

    final jwt = JWT({
      'sub': username,
      'name': name,
      'scope': scope,
      'exp': expirationTime.millisecondsSinceEpoch,
    });

    final token = jwt.sign(
      SecretKey(secret),
    );

    await _storage.write(
      key: _authTokenKey,
      value: token,
    );
  }

  @override
  String deriveSignKeyFromPassword(String password) {

    var hexPassword= SecurityService.sha256Hex(password);

    var derivedKey = _securityService.deriveKey(hexPassword);
    return derivedKey;
  }

  @override
  Future<String> loadMasterPassword() async {
    return await _storage.read(key: _masterPwdKey) ?? '';
  }

  @override
  Future<void> storeMasterPassword(String password) async {

    var hexPassword= SecurityService.sha256Hex(password);

    var derivedKey = _securityService.deriveKey(hexPassword);

    await _storage.write(key: _masterPwdKey, value: derivedKey);
  }

  @override
  Future<void> removeAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  @override
  String deriveSignKeyFromHashedPassword(String hashedPassword) {
    var derivedKey = _securityService.deriveKey(hashedPassword);

    return derivedKey;
  }

  @override
  Future<void> removeMasterPassword() {
    return _storage.delete(key: _masterPwdKey);
  }
}
