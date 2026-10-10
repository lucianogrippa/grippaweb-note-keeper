import 'package:note_keeper/app/domain/registration_data.dart';
import 'package:note_keeper/app/repositories/account_repository.dart';
import 'package:note_keeper/app/services/database_service.dart';

abstract class IRegistrationService {
  Future<bool> dbCreated();
  Future<bool> registerAccount(RegistrationData data);

  Future<void> deleteDatabase();
}

class RegistrationService implements IRegistrationService {
  final IDatabaseService _databaseService;
  final IAccountRepository _accountRepository;

  RegistrationService({
    required this._databaseService,
    required this._accountRepository,
  });


  @override
  Future<bool> registerAccount(RegistrationData data) async {
    // Check if an account already exists
    final existingAccounts = await _accountRepository.totalAccounts();
    if (existingAccounts > 0) {
      return false; // Account already exists
    }

    // Here you would typically insert the new account into the database
    // For example:
    await _accountRepository.createAccount(data);

    return true; // Registration successful
  }

  @override
  Future<bool> dbCreated() async {
    return await _databaseService.isDbExistsInSystem();
  }

  @override
  Future<void> deleteDatabase() async {
    await _databaseService.deleteDatabase();
  }
}
