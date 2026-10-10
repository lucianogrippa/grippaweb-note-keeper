import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
               await locator<AuthNotifier>().logout();

               if(context.mounted) {
                 context.go("/login");
               }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}