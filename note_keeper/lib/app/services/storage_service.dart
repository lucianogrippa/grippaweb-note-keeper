import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class IStorageService  {

  factory IStorageService.init() => StorageService.defaultState();
  String loadStoredAuthToken();
  Future<String> storeAuthToken(String username, String name, String scope, DateTime expirationTime, String signKey);
  StorageState get storageState;
}

class StorageState {
  late String authToken;
  late String dbPath = '';
}


class StorageService extends Notifier<StorageState>  implements IStorageService {

  @override
  final StorageState storageState;

  final FlutterSecureStorage storage;

  StorageService({required this.storage, required this.storageState});

  static StorageService defaultState() {
    return StorageService(
      storage: FlutterSecureStorage(
        webOptions: WebOptions(
          dbName: 'note_keeper_storage_db',
        ),
        aOptions: AndroidOptions.biometric(
            biometricPromptTitle: 'Secure Note keeper',
            requireBiometricsPerOperation: false
        ),
        lOptions: LinuxOptions.defaultOptions,
      ),
      storageState: StorageState(),
    );
  }

  @override
  StorageState build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  String loadStoredAuthToken() {
    // TODO: implement loadStoredAuthToken
    throw UnimplementedError();
  }

  @override
  Future<String> storeAuthToken(String username, String name, String scope, DateTime expirationTime, String signKey) async {

    final secret = '$username|${expirationTime.toIso8601String()}|$signKey';

    final jwt = JWT({
      'sub': username,
      'name': name,
      'scope': scope,
      'exp': expirationTime.millisecondsSinceEpoch,
    });

    final token = jwt.sign(SecretKey(secret));

    await storage.write(key: 'note-keeper-authToken', value: token);
    return token;
  }
}
