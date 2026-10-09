import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/services/registration_service.dart';

import '../../app/domain/registration_data.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(
    debugLabel: 'registrationForm',
  );
  final ValueNotifier<bool> _isFormValid = ValueNotifier<bool>(false);

  RegistrationData registrationData = RegistrationData.empty();

  bool _btnCancelEnabled = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureMasterPassword = true;
  bool _obscureConfirmMasterPassword = true;

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _masterPasswordController = TextEditingController();
  final _confirmMasterPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _btnCancelEnabled = true;
    _obscurePassword = true;
    _obscureConfirmPassword = true;
    _obscureMasterPassword = true;
    _obscureConfirmMasterPassword = true;
  }

  ScaffoldMessengerState? _scaffoldMessenger;
  NavigatorState? _navigatorState;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _masterPasswordController.dispose();
    _confirmMasterPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    _navigatorState = Navigator.of(context);
    var screenSize = MediaQuery.of(context).size;

    var boxW = screenSize.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,

              child: ConstrainedBox(
                // Constrain the width, but let the height adapt dynamically to the children
                constraints: BoxConstraints(maxWidth: boxW),
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

                    // Second Card: Master Password Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // title master password
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Master Password",
                                textAlign: TextAlign.center,

                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // master password
                            TextFormField(
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureMasterPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureMasterPassword =
                                          !_obscureMasterPassword;
                                    });
                                  },
                                ),
                                hintText: 'Enter your master password',
                              ),
                              controller: _masterPasswordController,
                              obscureText: _obscureMasterPassword,
                              validator: _validateMasterPassword,
                              onChanged:(_)=> _validateForm(),
                            ),

                            const SizedBox(height: 16),
                            // confirm master password
                            TextFormField(
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmMasterPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmMasterPassword =
                                          !_obscureConfirmMasterPassword;
                                    });
                                  },
                                ),
                                hintText: 'Confirm your master password',
                              ),
                              controller: _confirmMasterPasswordController,
                              obscureText: _obscureConfirmMasterPassword,
                              validator: _confirmMasterPassword,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [

                            // register button
                            ValueListenableBuilder<bool>(
                              valueListenable: _isFormValid,
                              builder: (context, value, child) {
                                return ElevatedButton(
                                  onPressed: value  ?_submitRegistration : null,
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
    );
  }

  void _validateForm() {
    // currentState?.validate() restituisce true se tutti i validatori passano
    // Usiamo l'operatore di assegnazione per aggiornare il ValueNotifier
    _isFormValid.value = _formKey.currentState?.validate() ?? false;
  }

  void _submitRegistration() async {
    var result = await _registerAccount();
    if (result) {
      _navigatorState?.pushReplacementNamed('/login');
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

  ///
  /// Confirm Master Password validation function. It checks if the confirmed master password matches the chosen master password.
  ///
  ///
  String? _confirmMasterPassword(String? value) {
    var currentMasterPassword = _masterPasswordController.text.trim();

    if (value == null || value.isEmpty) {

      return 'Please confirm your master password';
    }
    if (value != currentMasterPassword) {
      return 'Passwords do not match';
    }
    //checkForEnableRegisterButton();
    return null;
  }

  ///
  /// Validation function for master password
  ///
  String? _validateMasterPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your master password';
    }

    var isPasswordMeetCriteria = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_])[A-Za-z\d@$!%*?&_]{10,}$',
    ).hasMatch(value);

    if (!isPasswordMeetCriteria) {
      return "The password does not meet the criteria. 10 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character.";
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
      registrationData.masterPassword = _masterPasswordController.text.trim();
      registrationData.masterPasswordConfirmed = _confirmMasterPasswordController.text.trim() == registrationData.masterPassword;

      var storageService = await ref.read(storageServiceProvider.future);

      if (registrationData.masterPasswordConfirmed &&
          registrationData.passwordConfirmed) {
        // store master password in secure storage


        await storageService.storeMasterPassword(
          registrationData.masterPassword,
        );
      }

      // check if master password is ready stored in secure storage
      var isMasterPasswordExists = await storageService.isMasterPasswordExists();

      if(!isMasterPasswordExists) {
        _scaffoldMessenger?.showSnackBar(
          const SnackBar(content: Text('Failed to store master password')),
        );
        return false;
      }
      // create account
      var accountService = await ref.read(registrationServiceProvider.future);

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
      _cleanUpFailedRegistration();
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
      var storageService = await ref.read(storageServiceProvider.future);

      var masterPassword = await storageService.loadMasterPassword();

      if (masterPassword.isNotEmpty) {
        var accountService = await ref.read(registrationServiceProvider.future);

        var dbExists = await accountService.dbCreated();

        if (dbExists) {
          // delete db
          await accountService.deleteDatabase();
        }

        await storageService.removeMasterPassword();
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
