import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:note_keeper/app/domain/registration_data.dart';
import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/domain/user_profile.dart';
import 'package:note_keeper/app/providers/app_provider.dart';



/// repository provider
final FutureProvider<IAccountRepository> accountRepositoryProvider = FutureProvider((ref) async {
  final databaseService = ref.watch(databaseProvider);
  final  storageService = await ref.watch(storageServiceProvider.future);

  final password = await storageService.loadMasterPassword();

  if(password.isEmpty){
    throw ArgumentError("Master Password for database cannot be empty");
  }

  await databaseService.open<UserProfile, UserProfileAdapter>(table: "user_profile", password: password);

  final db = databaseService.dataSource();
  /// inject datasource to account repository
  return IAccountRepository.create(db);
});


/// Repository interface for account-related database operations
abstract class IAccountRepository {

  Future<int> totalAccounts();

  factory IAccountRepository.create(Box? db) => AccountRepository(db:db);


  Future<Account> findByUsername(String username);

  Future<String> loadHashedPassword(String username);

  Future<void> createAccount(RegistrationData data);
}

/// Repository implementation for account-related database operations
class AccountRepository implements IAccountRepository {

  final Box? _db;

  AccountRepository({required this._db});

  @override
  Future<int> totalAccounts() async {
    final result = await _db.get("user_profile", defaultValue: null);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<Account> findByUsername(String username) async {
    final result = await _db?.values.firstOrNull(where: (row) => row['username'] == username);

    if (result.isNotEmpty) {
      final row = result.first;
      return Account.fromUser(user: User(
        id: row['id'] as String,
        username: row['username'] as String,
        name: row['name'] as String,
        lastname: row['lastname'] as String,
        email: row['email'] as String,
      ));
    }

    return Account.empty();
  }

  @override
  Future<String> loadHashedPassword(String username) async {
    final result = await _db.query(
      'user_profile',
      columns: ['password_hash'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return result.first['password_hash'] as String;
    }

    return '';
  }

  @override
  Future<void> createAccount(RegistrationData data) async {

    if(data.masterPasswordConfirmed && data.passwordConfirmed){

      // check if account exists
      var accountExist = await totalAccounts() > 0;

      if(accountExist){
        throw ArgumentError("Account already exists");
      }

      await _db.insert(
        'user_profile',
        {
          'username': data.username,
          'name': data.name,
          'lastname': data.lastname,
          'email': data.email,
          'password_hash': data.password,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return Future.value();
    }

    throw ArgumentError("Master Password and Password must be confirmed");
  }

}

