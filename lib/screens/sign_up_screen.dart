import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const String routeName = '/sign-up';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //Controllers 
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialCharacterPattern = RegExp(
    r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]`~+=;]',
  );


  //destroy all space
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  //submit the password and username and save it, it is not implmented right now
  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(
      DashboardScreen.routeName, // Send to Dashboard Screen
      arguments: _usernameController.text.trim(),
    );
  }


  //Validate password to make sure it is the correct size and has the right requirements
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!_specialCharacterPattern.hasMatch(value)) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign Up',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next, // Go onto the next text field
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done, //Go onto the button to submit
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create Account'),
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
}
