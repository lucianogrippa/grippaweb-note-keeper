
import 'dart:convert';
import 'dart:typed_data';

import 'package:argon2/argon2.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class SecurityService {

  late Argon2Parameters parameters;

  /// Init Argon2 parameters with salt and default values for iterations, memory and version
  /// for version 1.0 and ARGON2_i
  SecurityService._v10(String salt) {

    var encodedSalt = salt.toBytesUTF8();

    parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_i,
      encodedSalt,
      version: Argon2Parameters.ARGON2_VERSION_10,
      iterations: 3,
      memory: 65536,
      memoryPowerOf2: 16,
    );
  }

  /// Init Argon2 parameters with salt and default values for iterations, memory and version
  /// for version 1.3 and ARGON2_id
  SecurityService._v13(String salt) {

    parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt.toBytesUTF8(),
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: 3,
      memory: 65536,
      memoryPowerOf2: 16,
    );

  }

  /// return derived hash key from password using Argon2 algorithm with the initialized parameters
  String deriveKey(String key) {

    var argon2 = Argon2BytesGenerator();
    argon2.init(parameters);

    var keyBytes = utf8.encode(key);

    var derivedKey = Uint8List(32);
    argon2.generateBytes(keyBytes, derivedKey, 0, derivedKey.length);

    return derivedKey.toHexString();
  }

  /// return true if derivedPassword is the same as the derived key from cleanPassword using Argon2 algorithm with the initialized parameters
  bool checkDerivedPassword(String cleanPassword, String derivedPassword) {
    var derivedKey = deriveKey(cleanPassword);
    return derivedKey == derivedPassword;
  }


  /// generate a unique key salt using UUID v4
  static String generateUniqueKeySalt() {
    var uuid = Uuid();
    String uniqueId = uuid.v4();
    return uniqueId.toBytesUTF8().toHexString();
  }

  static String sha256Hex(String key){

    var bytes = utf8.encode(key);
    var digest = sha256.convert(bytes);
    return digest.toString();

  }

  factory SecurityService.initV13Salt() => SecurityService._v13(SecurityService.generateUniqueKeySalt());

  factory SecurityService.initV10Salt() => SecurityService._v10(SecurityService.generateUniqueKeySalt());

  factory SecurityService.initV10FixedSalt(String salt) => SecurityService._v10(salt);

  factory SecurityService.initV13FixedSalt(String salt) => SecurityService._v13(salt);

}