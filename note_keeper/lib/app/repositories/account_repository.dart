import 'package:hive_ce/hive.dart';
import 'package:note_keeper/app/domain/registration_data.dart';
import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/domain/user_profile.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/app/services/security_service.dart';

/// Repository interface for account-related database operations
abstract class IAccountRepository {
  Future<int> totalAccounts();

  Future<Account> findByUsername(String username);

  Future<String> loadDerivedPassword(String username);

  Future<void> createAccount(RegistrationData data);

  Future<void> updateLastAccess(String username, DateTime lastAccess);

  Future<bool> isAccountExists(String username);

  Future<void> openDatabase();

  factory IAccountRepository.create(IDatabaseService databaseService)  => AccountRepository(databaseService: databaseService);

}

/// Repository implementation for account-related database operations
class AccountRepository implements IAccountRepository {
  Box<UserProfile>? _db;

  final IDatabaseService _databaseService;

  AccountRepository({required this._databaseService});


  @override
  Future<int> totalAccounts() async {
    return _db?.length ?? 0;
  }

  @override
  Future<Account> findByUsername(String username) async {
    final result = await _db?.values
        .where((row) => row.email == username)
        .firstOrNull;

    if (result != null) {
      return Account.fromUser(
        user: User(
          id: result.id,
          name: result.name,
          lastname: result.lastname,
          email: result.email,
        ),
        expiredDate: DateTime.now().add(const Duration(days: 15)),
      );
    }

    return Account.empty();
  }

  @override
  Future<String> loadDerivedPassword(String username) async {
    final result = await _db?.values
        .where((row) => row.email == username)
        .firstOrNull;

    if (result != null && result.id.isNotEmpty) {
      return result.passwordHash;
    }

    return '';
  }

  @override
  Future<void> createAccount(RegistrationData data) async {
    if (data.passwordConfirmed) {
      // check if account exists
      var accountExist = await totalAccounts() > 0;

      if (accountExist) {
        throw ArgumentError("Account already exists");
      }

      var hashPassword = _databaseService.hashPassword(data.password);

      // generate id
      final uniqueId = SecurityService.generateUniqueKeySalt();

      await _db?.put(
        uniqueId,
        UserProfile()
          ..id= uniqueId
          ..name = data.name
          ..lastname = data.lastname
          ..email = data.email
          ..passwordHash = hashPassword
          ..createdAt = DateTime.now()
          ..lastAccess = DateTime.now(),
      );

      return Future.value();
    }

    throw ArgumentError("Master Password and Password must be confirmed");
  }

  @override
  Future<void> updateLastAccess(String username, DateTime lastAccess) {
    final result =
        _db?.values.where((row) => row.email == username).toList() ?? [];

    if (result.isNotEmpty) {
      final row = result.first;
      row.lastAccess = lastAccess;

      _db?.put(row.id, row);
      return Future.value();
    }

    throw ArgumentError("User not found");
  }

  @override
  Future<bool> isAccountExists(String username) async {
    final result = await _db?.values
        .where((row) => row.email == username)
        .firstOrNull;
    return result != null;
  }

  @override
  Future<void> openDatabase() async {
    _db = await _databaseService.open<UserProfile>(
      table: 'user_profile',
      adapter: UserProfileAdapter(),
    );
  }
}
