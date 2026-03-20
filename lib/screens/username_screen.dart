import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/providers.dart';
import 'dashboard_screen.dart';


//Consumer Widget to set someones username 
class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  //Route name
  static const String routeName = '/username-selection';


  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}


//State class
class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  //To extract the name 
  final _usernameController = TextEditingController();
  bool _isSubmitting = false;


  //Destroy function
  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in.')),
      );
      return;
    }
    //Loading button
    setState(() => _isSubmitting = true);

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final username = _usernameController.text.trim();
      

      //Use the profile service to update the username
      await userProfileService.updateUsername(
        uid: user.uid,
        username: username,
      );

      if (!mounted) return;
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        DashboardScreen.routeName,
        (route) => false,
        arguments: username,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save username: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Username'),
        automaticallyImplyLeading: false, // User must set username to proceed
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                      'Almost there!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please choose a username to represent you in ArbiTrac.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'e.g. SharpBettor99',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required.';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(_isSubmitting ? 'Saving...' : 'Set Username'),
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
