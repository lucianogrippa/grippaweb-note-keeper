import 'package:note_keeper/app/services/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final storageService = IStorageService.init();

@riverpod
StorageState storageProvider(Ref ref) {
  return storageService.storageState;
}