import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class IStorageService {

  factory IStorageService.init() => StorageService(storage: FlutterSecureStorage());
}

class StorageService implements IStorageService {

  final FlutterSecureStorage storage;

  StorageService({required this.storage});
}
