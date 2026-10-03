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

  RegistrationData registrationData = RegistrationData.empty();

  bool btnRegisterEnabled = false;
  bool btnCancelEnabled = true;

  late final ScaffoldMessengerState _scaffoldMessenger;
  late final NavigatorState _navigatorState;

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

                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your first name',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }

                                setState(() => registrationData.name = value);
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your last name',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }

                                setState(
                                  () => registrationData.lastname = value,
                                );
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your email',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }

                                setState(() => registrationData.email = value);
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your password',
                              ),
                              obscureText: true,
                              validator: _validatePassword,
                              onChanged: (value) => setState(
                                () => registrationData.password = value,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Confirm your password',
                              ),
                              obscureText: true,
                              validator: _confirmPassword,
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

                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your master password',
                              ),
                              obscureText: true,
                              validator: _validateMasterPassword,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Confirm your master password',
                              ),
                              obscureText: true,
                              validator: _confirmMasterPassword,
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
                            ElevatedButton(
                              onPressed: () async {
                                var result = await _registerAccount();
                                if (result) {
                                  _navigatorState.pushReplacementNamed('/login');
                                }
                              },
                              child: const Text('Register'),
                            ),
                            ElevatedButton(
                              onPressed: () => _formKey.currentState!.reset(),
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

  ///
  /// Validate function for password
  ///
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    var isPasswordMeetCriteria = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    ).hasMatch(value);

    if (!isPasswordMeetCriteria) {
      return "The password does not meet the criteria. 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character.";
    }

    setState(() {
      registrationData.password = value;
    });

    return null;
  }

  ///
  /// Confirm Password validation function. It checks if the confirmed password matches the chosen password.
  ///
  ///
  String? _confirmPassword(String? value) {
    var chosePassword = registrationData.password;

    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != chosePassword) {
      return 'Passwords do not match';
    }

    setState(() {
      registrationData.passwordConfirmed = true;
      registrationData.password = value;
    });
    return null;
  }

  ///
  /// Confirm Master Password validation function. It checks if the confirmed master password matches the chosen master password.
  ///
  ///
  String? _confirmMasterPassword(String? value) {
    var currentMasterPassword = registrationData.masterPassword;

    if (value == null || value.isEmpty) {
      setState(() {
        registrationData.masterPasswordConfirmed = false;
      });

      return 'Please confirm your master password';
    }
    if (value != currentMasterPassword) {
      setState(() {
        registrationData.masterPasswordConfirmed = false;
      });

      return 'Passwords do not match';
    }

    setState(() {
      registrationData.masterPassword = value;
      registrationData.masterPasswordConfirmed = true;
    });
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
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{10,}$',
    ).hasMatch(value);

    if (!isPasswordMeetCriteria) {
      return "The password does not meet the criteria. 10 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character.";
    }

    setState(() {
      registrationData.masterPassword = value;
    });
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
      // Process data.

      // disable Register button and cancel button

      setState(() {
        // Disable Register and Clear buttons
        btnRegisterEnabled = false;
        btnCancelEnabled = false;
      });

      _scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Processing Data')),
      );

      if(registrationData.masterPasswordConfirmed && registrationData.passwordConfirmed) {

        // store master password in secure storage
        var storageService = await ref.read(storageServiceProvider.future);

        await storageService.storeMasterPassword(registrationData.masterPassword);
      }

      // create account
      var accountService = await ref.read(registrationServiceProvider.future);

      var isAccountCreated = await accountService.registerAccount(
        registrationData,
      );

      if (isAccountCreated) {
        _scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Account successfully created')),
        );
        _formKey.currentState!.reset();
        return true;
      }

      _scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to create account')),
      );
    } catch (e) {
      _cleanUpFailedRegistration();
      _scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        // Re-enable Register and Clear buttons
        btnRegisterEnabled = true;
        btnCancelEnabled = true;
      });
    }

    return false;
  }


  Future<void> _cleanUpFailedRegistration() async {
    // Remove the master password from secure storage if registration fails
    try {
      var storageService = await ref.read(storageServiceProvider.future);
      
      var masterPassword = await storageService.loadMasterPassword();
      
      
      if(masterPassword.isNotEmpty) {
      
        var accountService = await ref.read(registrationServiceProvider.future);
      
        var dbExists = await accountService.dbCreated();
      
        if(dbExists) {
          // delete db
          await accountService.deleteDatabase();
        }
      
        await storageService.removeMasterPassword();
      }
    } on Exception catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace,label: "cleanUpFailedRegistration",maxFrames: 100);
    }

  }
}
