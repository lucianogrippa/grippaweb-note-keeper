
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/storage_state.dart';
import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {

  late final IAccountService _accountService;
  late final IStorageService _storageService;

  @override
  FutureOr<AuthState> build() async {

    _accountService = ref.watch(accountServiceProvider);
    _storageService = ref.watch(storageServiceProvider);

    StorageState storage = await _storageService.build();

    if(storage.hasAuthToken) {
      final account = await _accountService.fromToken(storage.storedToken);
      return await _accountService.checkSession(account);
    }

    return AuthState.unauthenticated();
  }

  Future<bool> checkSession(Account account) async {
    update((actualState) async=> actualState = await _accountService.checkSession(account));
    return state.value?.status == AuthStatus.authenticated;
  }

  Future<void> authenticate(String username, String password) async {
    final account = await _accountService.login(username, password);

    var authState = account.username.isNotEmpty ? AuthState.authenticated(account) : AuthState.withError("Invalid username or password");


    update((actualState) =>  actualState = authState);
  }

  Future<void> logout() async {
    await _accountService.logout();
    state = AsyncData(AuthState.unauthenticated());
  }
}

/// provide auth notifier
final authNotifierProvider = Provider((ref) {
  return ref.watch(authStateProvider.notifier);
});