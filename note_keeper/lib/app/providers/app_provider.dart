import 'package:get_it/get_it.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/repositories/account_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/app/services/registration_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';

import '../repositories/category_repository.dart';

// Create a global instance (or use GetIt.instance)
final locator = GetIt.instance;

void configureLocators() {


  locator.registerSingletonAsync<IStorageService>(
    () async {
      var storage = StorageService();
      await storage.build();
      return storage;
    },
  );

  // DB and Repositories
  // Register your services here
  locator.registerSingletonWithDependencies<IDatabaseService>(
    () => DatabaseService(storageService: locator<IStorageService>()),
    dependsOn: [IStorageService],
  );

  locator.registerSingletonAsync<IAccountRepository>(
    () async {
      var repository = IAccountRepository.create(locator<IDatabaseService>());
      await repository.open();
      return repository;
    },
    dependsOn: [IDatabaseService],
  );

  locator.registerSingletonAsync<INoteCategoryRepository>(
    () async {
      var repository = INoteCategoryRepository.create(locator<IDatabaseService>());
      await repository.open();
      return repository;
    },
    dependsOn: [IDatabaseService],
  );

  ////////////////////////////////////////////////////////////////////////

  locator.registerSingletonWithDependencies<IAccountService>(
      ()=>
    IAccountService.init(
      storageService: locator<IStorageService>(),
      accountRepository: locator<IAccountRepository>(),
    ),
    dependsOn: [IStorageService,IAccountRepository]
  );

  locator.registerSingletonWithDependencies<IRegistrationService>(
    () => RegistrationService(
      databaseService: locator<IDatabaseService>(),
      accountRepository: locator<IAccountRepository>(),
    ),
    dependsOn: [IDatabaseService, IAccountRepository],
  );

  /// Notifiers
  locator.registerSingletonWithDependencies(() => AuthNotifier(), dependsOn: [IStorageService,IAccountService]);
  locator.registerSingleton<LoadingNotifier>(LoadingNotifier());

}
