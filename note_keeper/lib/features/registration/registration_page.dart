import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}


class _RegistrationPageState extends ConsumerState<RegistrationPage> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(debugLabel: 'registrationForm');

  @override
  Widget build(BuildContext context) {

    var screenSize = MediaQuery.of(context).size;

    var boxW  = screenSize.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                // Constrain the width, but let the height adapt dynamically to the children
                constraints: BoxConstraints(
                  maxWidth: boxW,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Registration Page",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),

                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Enter your first name'),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter your first name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Enter your last name'),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter your last name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Enter your email'),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Enter your password'),
                              obscureText: true,
                              validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Confirm your password'),
                              obscureText: true,
                              validator: (value) => value == null || value.isEmpty ? 'Please confirm your password' : null,
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),


                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Enter your master password'),
                              obscureText: true,
                              validator: (value) => value == null || value.isEmpty ? 'Please enter a password' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Confirm your master password'),
                              obscureText: true,
                              validator: (value) => value == null || value.isEmpty ? 'Please confirm your master password' : null,
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
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // Process data.
                                }
                              },
                              child: const Text('Register'),
                            ),
                            ElevatedButton(

                              onPressed: () {
                                _formKey.currentState!.reset();
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

          ),
        ),
      ),
    );
  }
}