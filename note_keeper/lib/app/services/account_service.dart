
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/user_account.dart';

abstract class IAccountService {


  /// Login with username and password
  /// You have do it just first time in order to
  Future<Account> login(String username,String password);

  /// Logout from session and remove stored temporary token from cache
  Future<void> logout();


  Future<AuthState> checkSession();

  factory IAccountService.create() => AccountService();
}


class AccountService implements IAccountService {

  @override
  Future<AuthState> checkSession() {
    // TODO: implement checkSession
    throw UnimplementedError();
  }

  @override
  Future<Account> login(String username, String password  ) {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }

}