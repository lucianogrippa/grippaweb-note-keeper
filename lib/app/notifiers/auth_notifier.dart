
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';

class AuthNotifier extends ChangeNotifier {

  late final IAccountService _accountService;
  late final IStorageService _storageService;

  late AuthState state;

  AuthNotifier() {
    state = AuthState.unauthenticated();

    build().then((_) {
      notifyListeners();
    });
  }

  Future<void> build() async {

    _accountService = locator<IAccountService>();
    _storageService = locator<IStorageService>();

    var token = await _storageService.loadStoredAuthToken();

    if(token.isNotEmpty) {
      state = await _accountService.checkSessionFromStoredToken();
      notifyListeners();
      return;
    }

    state = AuthState.unauthenticated();
    notifyListeners();
  }

  Future<bool> checkSession() async {
    state = await _accountService.checkSessionFromStoredToken();

    notifyListeners();
    return state.status == AuthStatus.authenticated;
  }

  Future<bool> isAccountRegistered() async {
    return await _accountService.isAccountExists();
  }

  Future<void> authenticate(String username, String password) async {
    final account = await _accountService.login(username, password);

   state = account.email.isNotEmpty ? AuthState.authenticated(account) : AuthState.withError("Invalid username or password");

   notifyListeners();
  }


  Future<void> logout() async {
    await _accountService.logout();
    state = AuthState.unauthenticated();
  }
}