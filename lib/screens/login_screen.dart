import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/providers.dart';
import '../services/services.dart';
import 'main_layout_shell.dart';
import 'username_screen.dart';

//Stateful widget class
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  //Text controllers for username and password
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  //Destroy
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //Submit function
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
      final credential = await authService.signInWithEmail(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException('Login failed. Please try again.');
      }

      final hasUsername = await userProfileService.hasUsername(user.uid);
      if (!mounted) return;

      if (!hasUsername) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(UsernameScreen.routeName, (route) => false);
        return;
      }

      try {
        await userProfileService.loadDisplayName(
          uid: user.uid,
          fallbackEmail: user.email ?? email,
        );
      } on FirebaseException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Logged in, but user profile data could not be refreshed right now.',
              ),
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(MainLayoutShell.routeName, (route) => false);
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isSubmitting = true);
    try {
      final authService = ref.read(authServiceProvider);
      final userProfileService = ref.read(userProfileServiceProvider);
      final credential = await authService.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException(
          'Google Sign-in failed. Please try again.',
        );
      }

      final hasUsername = await userProfileService.hasUsername(user.uid);
      if (!mounted) return;

      if (!hasUsername) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(UsernameScreen.routeName, (route) => false);
        return;
      }

      try {
        // Try to load existing profile, otherwise initialize for new user
        await userProfileService.loadDisplayName(
          uid: user.uid,
          fallbackEmail: user.email ?? '',
        );
      } catch (e) {
        // If profile doesn't exist, initialize it
        try {
          await userProfileService.initializeForNewUser(
            uid: user.uid,
            email: user.email ?? '',
          );
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(MainLayoutShell.routeName, (route) => false);
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        // Safe OS practice
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              //Constrains the child
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
                    TextFormField(
                      //Text form field for controlling Username
                      controller: _usernameController,
                      textInputAction: TextInputAction
                          .next, // If we hit enter it will go to the next field
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
                      // Controls the password fields
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction
                          .done, // if we hit enter it will hit enter or done action on the next
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        _submit();
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(_isSubmitting ? 'Logging in...' : 'Login'),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _signInWithGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('Login with Google'),
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
