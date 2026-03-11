import 'package:flutter/material.dart';

import 'dashboard_screen.dart';


//Stateful widget class
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  //Text controllers for username and password
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  //Destroy  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //Submit function that is just a filler
  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(
      DashboardScreen.routeName, //Send to Dashboard Screen
      arguments: _usernameController.text.trim(),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea( // Safe OS practice 
        child: Padding( 
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox( //Constrains the child
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField( //Text form field for controlling Username
                      controller: _usernameController,
                      textInputAction: TextInputAction.next, // If we hit enter it will go to the next field
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField( // Controls the password fields 
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done, // if we hit enter it will hit enter or done action on the next 
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Login'),
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
