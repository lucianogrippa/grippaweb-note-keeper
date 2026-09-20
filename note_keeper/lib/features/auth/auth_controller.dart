
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/services/account_service.dart';

class AuthController extends AsyncNotifier<AuthState> {

  final IAccountService accountService = IAccountService.create();

  @override
  FutureOr<AuthState> build() async {
    return await checkSession(Account.empty());
  }

  Future<AuthState> checkSession(Account account) async {
    return await accountService.checkSession(account);
  }

  Future<void> authenticate(String username,String password) async {

    final account = await accountService.login(username, password);

    final autState = await accountService.checkSession(account);

    if (account.isNotEmptyAccount() && autState.status == AuthStatus.authenticated)  {

      state = AsyncData(autState.copyWith(
        account: account
      ));


      return;
    }
  }

  Future<void> logout() async {
    await accountService.logout();
    state = AsyncData(AuthState.unauthenticated());
  }
}