import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/repositories/account_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';

/// Database provider
final Provider<IDatabaseService> databaseProvider = Provider<IDatabaseService>((ref) {
  return DatabaseService();
});

/// provide storage service
final Provider<IStorageService> storageServiceProvider = Provider<IStorageService>((ref) {
  return StorageService();
});


/// provide account service
final Provider<IAccountService> accountServiceProvider = Provider<IAccountService>((ref) {

    IStorageService storageService = ref.watch(storageServiceProvider);
    IAccountRepository accountRepository = ref.watch(accountRepositoryProvider);

    var accountService = IAccountService.create(storageService: storageService,
                                                accountRepository: accountRepository);

    return accountService;
});

/// auth state provider
final AsyncNotifierProvider<AuthNotifier, AuthState> authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
