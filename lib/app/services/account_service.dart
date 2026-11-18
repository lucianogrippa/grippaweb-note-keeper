
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/repositories/account_repository.dart';
import 'package:note_keeper/app/services/storage_service.dart';

abstract class IAccountService {


  /// Login with username and password
  /// You have do it just first time in order to
  Future<Account> login(String username, String password);

  /// Logout from session and remove stored temporary token from cache
  Future<AuthState> logout();

  Future<Account> fromToken(String? storedToken);


  Future<AuthState> checkSession(Account account);

  Future<AuthState> checkSessionFromStoredToken();

  /// Check if account is created in database, At least one account should be created in database,
  /// otherwise user should create account first
  Future<bool> isAccountExists();

  factory IAccountService.init({
    required IStorageService storageService,
    required IAccountRepository accountRepository}) =>
      AccountService(
          storageService: storageService,
          accountRepository: accountRepository);

}

class AccountService implements IAccountService {

  static final _maxTokenDurationInDays = 30;
  final IStorageService _storageService;
  final IAccountRepository _accountRepository;

  AccountService({required this._storageService, required this._accountRepository});

  /// Check if user is authenticated in session
  @override
  Future<AuthState> checkSession(Account account) async{
    return await verifyToken() && await isAccountExists() ?
                      Future.syncValue(AuthState.authenticated(account)) :
                      Future.syncValue(AuthState.unauthenticated());

  }

  @override
  Future<Account> login(String username, String password  ) async {


    Account account = await _accountRepository.findByUsername(username);

    if (account.email.isNotEmpty) {

      String incomingDerivedKey = await _accountRepository.loadDerivedPassword(account.email);

      String derivedKey = _storageService.deriveSignKeyFromPassword(password);

      if (derivedKey != incomingDerivedKey) {
        return Future.syncValue(Account.empty());
      }

      DateTime expireDate = DateTime.now().add(
          Duration(days: _maxTokenDurationInDays));


      account.expireDate = expireDate;
      account.login = DateTime.now();

      await _storageService.storeAuthToken(
          username, account.name, "auth", expireDate, derivedKey);

      return Future.syncValue(
          Account.fromUser(user: account, expiredDate: expireDate));
    }

    return Future.syncValue(Account.empty());
  }

  @override
  Future<AuthState> logout() async {
    await _storageService.removeAuthToken();
    return AuthState.unauthenticated();
  }

  Future<bool> verifyToken() async {
    var storedToken = await _storageService.loadStoredAuthToken();

    return storedToken.isNotEmpty && !await _checkTokenExpired(storedToken);
  }


  @override
  Future<Account> fromToken(String? storedToken) async {
    if(storedToken != null && storedToken.isNotEmpty) {

      var decodedToken = JWT.tryDecode(storedToken);

      if(decodedToken != null) {
        var username = decodedToken.payload['sub'];
        var exp = decodedToken.payload['exp'];

        Account account = await _accountRepository.findByUsername(username);

        if(account.email.isNotEmpty && exp != null) {
          var expireDate = DateTime.fromMillisecondsSinceEpoch(exp);

          if(DateTime.now().isAfter(expireDate)) {
            return Account.empty();
          }

          return Account.fromUser(
              user: account,
              expiredDate: expireDate)..login = DateTime.now();
        }
      }

      return Account.empty();
    }

    return Account.empty();
  }

  @override
  Future<bool> isAccountExists() async {

    var totalAccounts = await _accountRepository.totalAccounts();

    return totalAccounts > 0;
  }

  Future<bool> _checkTokenExpired(String storedToken) async {
    var decodedToken = JWT.tryDecode(storedToken);
    if (decodedToken == null) {
      return true;
    }

    var exp = decodedToken.payload['exp'];

    if (exp == null) {
      return true;
    }

    var expireDate = DateTime.fromMillisecondsSinceEpoch(exp);

    return DateTime.now().isAfter(expireDate);
  }

  @override
  Future<AuthState> checkSessionFromStoredToken() async {

    // load token
    var storedToken = await _storageService.loadStoredAuthToken();

    if(storedToken.isNotEmpty) {
      var isTokenValid = await verifyToken();
      if(isTokenValid) {
        var account = await fromToken(storedToken);
        return AuthState.authenticated(account);
      }
    }

    return AuthState.unauthenticated();
  }
}