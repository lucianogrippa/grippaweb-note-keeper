
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/user_account.dart';

abstract class IAccountService {


  /// Login with username and password
  /// You have do it just first time in order to
  Future<Account> login(String username,String password);

  /// Logout from session and remove stored temporary token from cache
  Future<AuthState> logout();


  Future<AuthState> checkSession(Account account);

  factory IAccountService.create() => AccountService();
}


class AccountService implements IAccountService {

  bool  hasToken = false;

  /// is true if database contains account is created and initialized
  bool isAccountDBInitialized = false;

  /// Check if user is authenticated in session
  @override
  Future<AuthState> checkSession(Account account) async{
    /// TODO: call authentication

    return await verifyToken() && await isDbInitialized() ?
                      Future.syncValue(AuthState.authenticated(account)) :
                      Future.syncValue(AuthState.unauthenticated());

  }

  @override
  Future<Account> login(String username, String password  ) {

    //TODO: Mocked Values
    if(username == 'admin' && password=='admin') {
      hasToken = true;
      return Future.syncValue(Account.mokAdmin());
    }

    hasToken = false;
    return Future.syncValue(Account.empty());
  }

  @override
  Future<AuthState> logout() {

    /// TODO: mocked values
      hasToken = false;
      return Future.syncValue(AuthState.unauthenticated());
  }

  Future<bool> verifyToken() {
    return Future.syncValue(hasToken);
  }

  Future<bool> isDbInitialized() async {
    return Future.syncValue(isAccountDBInitialized);
  }
}