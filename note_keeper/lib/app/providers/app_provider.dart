import 'package:get_it/get_it.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/notifiers/note_category_notifier.dart';
import 'package:note_keeper/app/notifiers/note_groups_notifier.dart';
import 'package:note_keeper/app/repositories/account_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/app/services/registration_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';

import '../repositories/category_repository.dart';

// Create a global instance (or use GetIt.instance)
final locator = GetIt.instance;

void configureLocators() {
  locator.registerSingletonAsync<IStorageService>(() async {
    var storage = StorageService();
    await storage.build();
    return storage;
  });

  ////////////////// REPOSITORIES ///////////////////////////
  registerRepositories();

  /////// SERVICES /////////////////////////////////////////77
  registerServices();

  ////////////////////////////////////////////////////////////////////////

  /// Notifiers
  registerNotifier();
}

void registerNotifier() {
  locator.registerSingletonWithDependencies(
    () => AuthNotifier(),
    dependsOn: [IStorageService, IAccountService],
  );
  locator.registerSingleton<LoadingNotifier>(LoadingNotifier());
  locator.registerSingletonWithDependencies(
    () => NoteCategoryNotifier(locator<INoteCategoryRepository>()),
    dependsOn: [INoteCategoryRepository],
  );

  locator.registerSingletonWithDependencies(
    () => NoteGroupsNotifier(
      locator<INoteCategoryRepository>(),
      locator<INoteGroupRepository>(),
    ),
    dependsOn: [INoteCategoryRepository, INoteGroupRepository],
  );
}

void registerRepositories() {
  locator.registerSingletonWithDependencies<IDatabaseService>(
    () => DatabaseService(storageService: locator<IStorageService>()),
    dependsOn: [IStorageService],
  );

  locator.registerSingletonAsync<IAccountRepository>(() async {
    var repository = IAccountRepository.create(locator<IDatabaseService>());
    await repository.open();
    return repository;
  }, dependsOn: [IDatabaseService]);

  locator.registerSingletonAsync<INoteCategoryRepository>(() async {
    var repository = INoteCategoryRepository.create(
      locator<IDatabaseService>(),
    );
    await repository.open();
    return repository;
  }, dependsOn: [IDatabaseService]);

  locator.registerSingletonAsync<INoteGroupRepository>(() async {
    var repository = INoteGroupRepository.create(locator<IDatabaseService>());
    await repository.open();
    return repository;
  }, dependsOn: [IDatabaseService]);

  locator.registerSingletonAsync<INoteRepository>(() async {
    var repository = INoteRepository.create(
      locator<IDatabaseService>(),
      locator<IStorageService>(),
    );
    await repository.open();
    return repository;
  }, dependsOn: [IDatabaseService, IStorageService]);
}

void registerServices() {
  locator.registerSingletonWithDependencies<IAccountService>(
    () => IAccountService.init(
      storageService: locator<IStorageService>(),
      accountRepository: locator<IAccountRepository>(),
    ),
    dependsOn: [IStorageService, IAccountRepository],
  );

  locator.registerSingletonWithDependencies<IRegistrationService>(
    () => RegistrationService(
      databaseService: locator<IDatabaseService>(),
      accountRepository: locator<IAccountRepository>(),
    ),
    dependsOn: [IDatabaseService, IAccountRepository],
  );
}
