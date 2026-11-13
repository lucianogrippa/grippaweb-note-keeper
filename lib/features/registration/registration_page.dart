import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/services/registration_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';
import 'package:note_keeper/features/widgets/theme_mode_selector.dart';

import '../../app/domain/registration_data.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(
    debugLabel: 'registrationForm',
  );
  final ValueNotifier<bool> _isFormValid = ValueNotifier<bool>(false);

  RegistrationData registrationData = RegistrationData.empty();

  bool _btnCancelEnabled = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _btnCancelEnabled = true;
    _obscurePassword = true;
    _obscureConfirmPassword = true;
  }

  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(actions: const [ThemeModeSelector()]),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,

              child: Center(child: ConstrainedBox(
                // Constrain the width, but let the height adapt dynamically to the children
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Registration Page",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // First Card: Profile Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            /// title
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Profile Information",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // name controller
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your first name',
                              ),
                              controller: _nameController,
                              validator: _validateName,
                              onChanged:(_)=> _validateForm(),
                            ),

                            const SizedBox(height: 16),

                            // last name controller
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your last name',
                              ),
                              controller: _lastNameController,
                              validator: _validateLastName,
                              onChanged:(_)=> _validateForm(),
                            ),

                            const SizedBox(height: 16),

                            // email
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your email',
                              ),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              onChanged:(_)=> _validateForm(),
                            ),

                            const SizedBox(height: 16),

                            // password
                            TextFormField(
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                hintText: 'Enter your password',
                              ),
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              onChanged:(_)=> _validateForm(),
                            ),

                            const SizedBox(height: 16),

                            // confirm password
                            TextFormField(
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                hintText: 'Confirm your password',
                              ),
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              validator: _confirmPassword,
                              onChanged:(_)=> _validateForm(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Third Card: Action Buttons
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: [

                            // register button
                            ValueListenableBuilder<bool>(
                              valueListenable: _isFormValid,
                              builder: (context, value, child) {
                                return ElevatedButton(
                                  onPressed: value  ? ()=>_submitRegistration(context) : null,
                                  child: const Text('Register'),
                                );
                              }
                            ),
                            ElevatedButton(
                              onPressed: _btnCancelEnabled
                                  ? () => _formKey.currentState!.reset()
                                  : null,
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _validateForm() {
    _isFormValid.value = _formKey.currentState?.validate() ?? false;
  }

  void _submitRegistration(BuildContext context) async {
    var result = await _registerAccount();
    if (result) {
      if(context.mounted) {
        context.go('/login');
      }
    }
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your last name';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your first name';
    }

    //setState(() => registrationData.name = value.trim());
    //checkForEnableRegisterButton();
    return null;
  }



  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // validate email
    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email address';
    }

    //setState(() => registrationData.email = value.trim());
    //checkForEnableRegisterButton();
    return null;
  }

  ///
  /// Validate function for password
  ///
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    var isPasswordMeetCriteria = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_])[A-Za-z\d@$!%*?&_]{8,}$',
    ).hasMatch(value);

    if (!isPasswordMeetCriteria) {
      return "The password does not meet the criteria. 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character.";
    }

    //checkForEnableRegisterButton();
    return null;
  }

  ///
  /// Confirm Password validation function. It checks if the confirmed password matches the chosen password.
  ///
  ///
  String? _confirmPassword(String? value) {
    var chosePassword = _passwordController.text.trim();

    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != chosePassword) {
      return 'Passwords do not match';
    }

    //checkForEnableRegisterButton();
    return null;
  }


  Future<bool> _registerAccount() async {
    try {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please correct the errors in the form'),
          ),
        );
        return false;
      }

      setState(() {
        // Disable Register and Clear buttons
        _btnCancelEnabled = false;
      });

      _scaffoldMessenger?.showSnackBar(
        const SnackBar(content: Text('Processing Data')),
      );

      registrationData.name = _nameController.text.trim();
      registrationData.lastname = _lastNameController.text.trim();
      registrationData.email = _emailController.text.trim();
      registrationData.password = _passwordController.text.trim();
      registrationData.passwordConfirmed = _confirmPasswordController.text.trim() == registrationData.password;

      if (!registrationData.passwordConfirmed) {
        _scaffoldMessenger?.showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return false;
      }
      // create account
      var accountService =  locator<IRegistrationService>();

      var isAccountCreated = await accountService.registerAccount(
        registrationData,
      );

      if (isAccountCreated) {
        _scaffoldMessenger?.showSnackBar(
          const SnackBar(content: Text('Account successfully created')),
        );
        _formKey.currentState!.reset();
        return true;
      }

      _scaffoldMessenger?.showSnackBar(
        const SnackBar(content: Text('Failed to create account')),
      );
    } catch (e) {
     await _cleanUpFailedRegistration();
      _scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        // Re-enable Register and Clear buttons
        _btnCancelEnabled = true;
      });
    }

    return false;
  }

  Future<void> _cleanUpFailedRegistration() async {
    // Remove the master password from secure storage if registration fails
    try {
      var storageService = locator<IStorageService>();

      var masterPassword = await storageService.loadMasterPassword();

      if (masterPassword.isNotEmpty) {
        var accountService = locator<IRegistrationService>();

        var dbExists = await accountService.dbCreated();

        if (dbExists) {
          // delete db
          await accountService.deleteDatabase();
        }
      }
    } on Exception catch (e, stackTrace) {
      debugPrintStack(
        stackTrace: stackTrace,
        label: "cleanUpFailedRegistration",
        maxFrames: 100,
      );
    }
  }
}
