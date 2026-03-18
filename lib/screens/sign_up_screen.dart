import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/providers.dart';
import '../services/services.dart';
import 'dashboard_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  static const String routeName = '/sign-up';

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  //Controllers
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialCharacterPattern = RegExp(
    r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]`~+=;]',
  );
  bool _isSubmitting = false;

  //destroy all space
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //submit the password and username and save it
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final email = _usernameController.text.trim();
    final password = _passwordController.text;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);


    try {
      final authService = ref.read(authServiceProvider);
      final userProfileService = ref.read(userProfileServiceProvider);
      //Sign up 
      final credential = await authService.signUpWithEmail(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException('Sign up failed. Please try again.');
      }

      String displayName = user.email ?? email;
      try {
        displayName = await userProfileService.initializeForNewUser(
          uid: user.uid,
          email: user.email ?? email,
        );
      } on FirebaseException{
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created, but profile data could not be saved right now.',
              ),
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        DashboardScreen.routeName,
        (route) => false,
        arguments: displayName,
      );
    } on AuthServiceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                      textInputAction:
                          TextInputAction.next, // Go onto the next text field
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required.';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction:
                          TextInputAction.done, //Go onto the button to submit
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) {
                        _submit();
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(
                        _isSubmitting
                            ? 'Creating Account...'
                            : 'Create Account',
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
}
