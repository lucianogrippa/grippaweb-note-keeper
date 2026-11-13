import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/services/storage_service.dart';

/// defines authentications status types
enum AuthStatus {
  loading,
  authenticated,
  authenticationError,
  unauthenticated,
}

/// This define Authentication states 
class AuthState {

  final AuthStatus status;
  final Account account;
  final String authError;

  late IStorageService storageService;

  AuthState({required this.status, required this.account, this.authError = ""});


  // factory for loading Auth State
  factory AuthState.loading() => AuthState(status: AuthStatus.loading, account: Account.empty());

  // factory for authenticate status
  factory AuthState.authenticated(Account account) => AuthState(status: AuthStatus.authenticated, account: account);

  // factory for unauthenticated status
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated, account: Account.empty());

  factory AuthState.withError(String error) {
    return AuthState(status: AuthStatus.authenticationError, account: Account.empty(), authError: error);
  }

  AuthState copyWith({AuthStatus? status, Account? account, String? authError}) {

    return AuthState(
      status: status ?? this.status,
      account: account ?? this.account,
      authError: authError ?? this.authError,
    );
  }
}