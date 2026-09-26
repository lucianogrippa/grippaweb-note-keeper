import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';

class LoginPage extends ConsumerStatefulWidget {



  LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();

}
class _LoginPageState extends ConsumerState<LoginPage>{

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(debugLabel: 'loginForm');

  String _username = "";
  String _password = "";

@override
  Widget build(BuildContext context) {


    var actualStatus = ref.watch(authStateProvider).value;

    String errorMessage = actualStatus?.authError ?? "";

    // get device screen size
    var screenSize = MediaQuery.of(context).size;

    var boxH = screenSize.height * 0.9;
    var boxW  = screenSize.width * 0.9;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Center(
            child: SizedBox(
              width: boxW,
              height: boxH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 25,
                children: [

                  Text("Login into account",style: TextStyle(fontSize: 22)),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: TextFormField(
                          key: Key('usernameField'),
                          decoration: const InputDecoration(hintText: 'Enter your username'),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'The username field is required';
                            }

                            setState(() {
                              _username = value;
                            });
                            return null;
                          },
                        ),
                      ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      key: Key('passwordField'),
                      decoration: const InputDecoration(hintText: 'Enter your password'),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'The password field is required';
                        }

                        setState(() {
                          _password = value;
                        });
                        return null;
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {

                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      String username = _username;
                      String password = _password;

                      await ref.read(authNotifierProvider).authenticate(
                        username,
                        password
                      );

                      final authStatus = ref.watch(authStateProvider).value?.status;

                      if(authStatus == AuthStatus.authenticated) {
                        // Navigate to the desired route
                        context.go('/home');
                      }
                    },
                    child: const Text('Login'),
                  ),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}