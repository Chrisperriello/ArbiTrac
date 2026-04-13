import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'theme.dart';

//Async function for updates
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Google Sign In for native platforms using google_sign_in package flow.
  if (_supportsNativeGoogleSignIn) {
    final googleClientId = DefaultFirebaseOptions.currentPlatform.iosClientId;
    await GoogleSignIn.instance.initialize(clientId: googleClientId);
  }

  runApp(const ProviderScope(child: MainApp()));
}

bool get _supportsNativeGoogleSignIn =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

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
    final selectedThemeAsync = ref.watch(appThemeSelectionProvider);
    final selectedTheme = selectedThemeAsync.asData?.value ?? AppThemeId.quant;
    final themeData = AppThemeRegistry.resolve(selectedTheme);
    return MaterialApp(
      theme: themeData,
      darkTheme: themeData,
      themeMode: ThemeMode.dark,
      themeAnimationDuration: const Duration(microseconds: 10),
      //themeAnimationCurve: Curves.elasticIn,
      home: const AuthGate(),
      routes: {
        //Routes for the main pages
        LoginScreen.routeName: (_) => const LoginScreen(), //Login Screen
        SignUpScreen.routeName: (_) => const SignUpScreen(), // Signup Screen
        UsernameScreen.routeName: (_) => const UsernameScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        CalculatorScreen.routeName: (_) => const CalculatorScreen(),
        MainLayoutShell.routeName: (_) => const MainLayoutShell(),
      },
    );
  }
}
