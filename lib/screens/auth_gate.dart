import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'dashboard_screen.dart';
import 'main_screen.dart';
import 'username_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const MainScreen();
        }

        // If user is logged in, check if they have a username
        final userProfileService = ref.read(userProfileServiceProvider);
        
        return FutureBuilder<bool>(
          future: userProfileService.hasUsername(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || snapshot.data == false) {
              return const UsernameScreen();
            }

            // User is logged in and has a username
            return const DashboardScreen();
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Auth Error: $error')),
      ),
    );
  }
}
