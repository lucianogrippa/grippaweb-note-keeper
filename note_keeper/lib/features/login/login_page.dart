import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';

class LoginPage extends StatefulWidget {



  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();

}
class LoginPageState extends State<LoginPage>{

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(debugLabel: 'loginForm');

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _formValid = ValueNotifier<bool>(false);

  final ValueNotifier<bool> _obscurePassword = ValueNotifier<bool>(true);

  final ValueNotifier<String> _errorMessage = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {

    _emailController.dispose();
    _passwordController.dispose();
    _isLoading.dispose();
    _formValid.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {


    var authNotifier = locator<AuthNotifier>();

    var actualStatus = authNotifier.state;
    _errorMessage.value = actualStatus.authError;


    // get device screen size
    var screenSize = MediaQuery.of(context).size;

    var boxH = screenSize.height * 0.9;
    var boxW  = screenSize.width * 0.9;


    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'Enter your email'),
                          controller: _emailController,
                          validator: _validateEmail,
                          onChanged:  (value) => _validateForm(),
                        ),
                      ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        suffixIcon: ValueListenableBuilder(
                          valueListenable: _obscurePassword,
                          builder: (context, value, child) {
                            return IconButton(
                              icon: Icon(
                                value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword.value = !_obscurePassword.value;
                                });
                              },
                            );
                          }
                        ),
                        hintText: 'Enter your password',
                      ),
                      key: Key('passwordField'),
                      validator: _validatePassword,
                      obscureText: _obscurePassword.value,
                      controller: _passwordController,
                      onChanged:  (value) => _validateForm(),
                    ),
                  ),

                  ValueListenableBuilder(
                    valueListenable: _formValid,
                    builder: (context, value, child) {
                      return ElevatedButton(
                        onPressed: value ? _login : null,
                        child: const Text('Login'),
                      );
                    }
                  ),
                  ValueListenableBuilder(
                    valueListenable: _errorMessage,
                    builder: (context, value, child) {
                      if (value.isNotEmpty) {
                        return Text(
                          value,
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _validateForm() {
    _formValid.value = _formKey.currentState?.validate() ?? false;
  }
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // validate email
    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email address';
    }
    // Add more email validation logic if needed
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    // Add more password validation logic if needed
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String username = _emailController.text.trim();
    String password = _passwordController.text.trim();

    var authNotifier = locator<AuthNotifier>();
    await authNotifier.authenticate(
      username,
      password
    );

    final authStatus = authNotifier.state.status;

    if(authStatus == AuthStatus.authenticated) {
      // Navigate to the desired route
      if (context.mounted) {
        context.go('/home');
      }

      return;
    }
    _errorMessage.value = authNotifier.state.authError;
  }
}