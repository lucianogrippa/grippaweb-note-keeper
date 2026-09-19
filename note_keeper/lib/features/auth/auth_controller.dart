
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/services/account_service.dart';

class AuthController extends AsyncNotifier<AuthState> {

  final IAccountService accountService = IAccountService.create();


  @override
  FutureOr<AuthState> build() async {
    return await checkSession();
  }

  Future<AuthState> checkSession() async {
    return await accountService.checkSession();
  }


}