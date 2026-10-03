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
final FutureProvider<IStorageService> storageServiceProvider = FutureProvider<IStorageService>((ref) async {
  var storageService = StorageService();
  await storageService.build();
  return storageService;
});


/// provide account service
final FutureProvider<IAccountService> accountServiceProvider = FutureProvider<IAccountService>((ref) async {

    IStorageService storageService = await ref.read(storageServiceProvider.future);
    IAccountRepository accountRepository = await ref.watch(accountRepositoryProvider.future);

    var accountService = IAccountService.init(storageService: storageService,
                                                accountRepository: accountRepository);

    return accountService;
});

/// auth state provider
final AsyncNotifierProvider<AuthNotifier, AuthState> authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
