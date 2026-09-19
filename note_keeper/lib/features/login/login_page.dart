import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/providers/app_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    return Scaffold(
      body: Center(

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 25,
          children: [
            Text("Login into account",style: TextStyle(
              fontSize: 22
            ),),

            ElevatedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).authenticate(
                  context,
                  'admin',
                  'admin',
                  '/home',
                  '/login-error',
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}