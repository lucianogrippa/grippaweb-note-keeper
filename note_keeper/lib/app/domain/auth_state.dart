/// defines authentications status types
enum AuthStatus {

  loading,
  authenticated,
  unauthenticated,
}

/// This define Authentication states 
class AuthState {
  final AuthStatus status;

  const AuthState({required this.status});


  // factory for loading Auth State
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  // factory for authenticate status
  factory AuthState.authenticated() => const AuthState(status: AuthStatus.authenticated);

  // factory for unauthenticated status
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
}