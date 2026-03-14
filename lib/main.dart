import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'screens/screens.dart';
import 'theme.dart';

//Async function for updates
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      initialRoute: MainScreen.routeName,
      routes: {
        //Routes for the main pages
        MainScreen.routeName: (_) => const MainScreen(), //Main screen
        LoginScreen.routeName: (_) => const LoginScreen(), //Login Screen
        SignUpScreen.routeName: (_) => const SignUpScreen(), // Signup Screen
        DashboardScreen.routeName: (_) =>
            const DashboardScreen(), // Dashboard screen
      },
    );
  }
}
