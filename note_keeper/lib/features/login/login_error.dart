import 'package:flutter/material.dart';


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
            Text("Ops Error: $errorMessage"),
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