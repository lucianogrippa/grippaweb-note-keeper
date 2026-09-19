
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/services/account_service.dart';

class AuthController extends AsyncNotifier<AuthState> {

  final IAccountService accountService = IAccountService.create();

  Account sessionAccount = Account.empty();


  @override
  FutureOr<AuthState> build() async {
    return await checkSession();
  }

  Future<AuthState> checkSession() async {
    return await accountService.checkSession();
  }

  Future<void> authenticate(BuildContext context, String username,
      String password, String destinationRoute, String errorLoginPath) async {
    final account = await accountService.login(username, password);

    final autState = await accountService.checkSession();

    if (account.isNotEmptyAccount() && autState.status == AuthStatus.authenticated)  {

      sessionAccount = account;
      ref.notifyListeners();
      return;
    }

    context.go(errorLoginPath);
  }
}