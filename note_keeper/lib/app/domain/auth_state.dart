import 'package:note_keeper/app/domain/user_account.dart';

/// defines authentications status types
enum AuthStatus {

  loading,
  authenticated,
  unauthenticated,
}

/// This define Authentication states 
class AuthState {
  final AuthStatus status;
  final Account account;

  const AuthState({required this.status, required this.account});


  // factory for loading Auth State
  factory AuthState.loading() => AuthState(status: AuthStatus.loading, account: Account.empty());

  // factory for authenticate status
  factory AuthState.authenticated( Account account) => AuthState(status: AuthStatus.authenticated, account: account);

  // factory for unauthenticated status
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated, account: Account.empty());

  AuthState copyWith({AuthStatus? status, Account? account}) {
    return AuthState(
      status: status ?? this.status,
      account: account ?? this.account,
    );
  }
}