import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/providers/app_provider.dart';


class  LoginErrorMessages {
  static final USERNAME_PASSWORD_WRONG = "Wrong Username or Password";
}

class LoginErrorPage extends StatelessWidget {

  final String errorMessage;

  const LoginErrorPage({super.key , required this.errorMessage});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("Ops Error: ${this.errorMessage}"),
            ElevatedButton(
              onPressed: () async {
              },
              child: const Text('Return back to login'),
            ),
          ],
        ),
      ),
    );
  }
}