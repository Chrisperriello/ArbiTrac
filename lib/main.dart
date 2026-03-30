import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'theme.dart';

//Async function for updates
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  





  

  // Initialize Google Sign In for version 7.x
  await GoogleSignIn.instance.initialize(
    clientId: '188999838435-u1dk63enaul40ip75h1cgv6dae3rdcim.apps.googleusercontent.com',
  );

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppRoot();
  }
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkModeAsync = ref.watch(appThemeModeProvider);
    final isDarkMode = isDarkModeAsync.asData?.value ?? false;
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
      routes: {
        //Routes for the main pages
        LoginScreen.routeName: (_) => const LoginScreen(), //Login Screen
        SignUpScreen.routeName: (_) => const SignUpScreen(), // Signup Screen
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        UsernameScreen.routeName: (_) => const UsernameScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
    );
  }
}
