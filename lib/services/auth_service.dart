import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as gsiap;

import '../core/config/app_config.dart';
import '../core/platform/platform_detector.dart';

bool get _supportsNativeGoogleSignIn =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, gsi.GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? gsi.GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final gsi.GoogleSignIn _googleSignIn;
  gsiap.GoogleSignIn? _desktopGoogleSignIn;
  static const Duration _googleSignInTimeout = Duration(seconds: 20);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    try {
      if (_supportsNativeGoogleSignIn) {
        await _googleSignIn.signOut();
      }
      if (isWindowsPlatform && _desktopGoogleSignIn != null) {
        await _desktopGoogleSignIn!.signOut();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_mapSignOutError(error.code));
    } catch (_) {
      throw const AuthServiceException('Sign out failed. Please try again.');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return _signInWithGoogleWeb();
      }
      if (isWindowsPlatform) {
        return _signInWithGoogleWindows();
      }
      if (!_supportsNativeGoogleSignIn) {
        throw const AuthServiceException(
          'Google Sign-In is not supported on this platform.',
        );
      }
      return _signInWithGoogleNative();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        'FirebaseAuthException(code: ${error.code}, message: ${error.message ?? ''})',
      );
    } catch (error) {
      if (error is AuthServiceException) rethrow;
      throw AuthServiceException(error.toString());
    }
  }

  Future<UserCredential> _signInWithGoogleWeb() async {
    final googleProvider = GoogleAuthProvider();
    return _auth.signInWithPopup(googleProvider);
  }

  Future<UserCredential> _signInWithGoogleWindows() async {
    final desktopSignIn = _desktopGoogleSignIn ??= gsiap.GoogleSignIn(
      params: gsiap.GoogleSignInParams(
        clientId: AppConfig.googleOAuthWebClientId,
        clientSecret: AppConfig.googleOAuthClientSecret,
        redirectPort: AppConfig.googleOAuthRedirectPort,
        scopes: const ['openid', 'email', 'profile'],
      ),
    );

    final credentials = await desktopSignIn.signIn().timeout(
      _googleSignInTimeout,
      onTimeout: () => throw const AuthServiceException(
        'Google Sign-in timed out. Please try again.',
      ),
    );
    if (credentials == null) {
      throw const AuthServiceException('Google Sign-in was canceled.');
    }
    final idToken = credentials.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException(
        'Google Sign-In did not return an ID token. Check your Google OAuth Web Client ID/Secret and localhost redirect URI.',
      );
    }
    return _signInToFirebaseWithGoogleTokens(
      accessToken: credentials.accessToken,
      idToken: idToken,
    );
  }

  Future<UserCredential> _signInWithGoogleNative() async {
    final googleUser = await _googleSignIn.authenticate().timeout(
      _googleSignInTimeout,
      onTimeout: () => throw const AuthServiceException(
        'Google Sign-in timed out. '
        'If this keeps happening on macOS, verify Xcode signing (Team) and keychain access.',
      ),
    );

    final googleAuth = googleUser.authentication;
    final existingAuthorization = await googleUser.authorizationClient
        .authorizationForScopes(['email', 'openid'])
        .timeout(
          _googleSignInTimeout,
          onTimeout: () => throw const AuthServiceException(
            'Google authorization timed out. Please try again.',
          ),
        );
    final accessToken =
        (existingAuthorization ??
                await googleUser.authorizationClient
                    .authorizeScopes(['email', 'openid'])
                    .timeout(
                      _googleSignInTimeout,
                      onTimeout: () => throw const AuthServiceException(
                        'Google authorization timed out. Please try again.',
                      ),
                    ))
            .accessToken;

    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException(
        'Google Sign-In did not return an ID token. Please try again.',
      );
    }

    return _signInToFirebaseWithGoogleTokens(
      accessToken: accessToken,
      idToken: idToken,
    );
  }

  Future<UserCredential> _signInToFirebaseWithGoogleTokens({
    required String accessToken,
    required String idToken,
  }) async {
    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
    final userCredential = await _auth
        .signInWithCredential(credential)
        .timeout(
          _googleSignInTimeout,
          onTimeout: () => throw const AuthServiceException(
            'Firebase sign-in timed out after Google authentication.',
          ),
        );
    if (userCredential.user == null) {
      throw const AuthServiceException(
        'Google Sign-in failed. Please try again.',
      );
    }
    return userCredential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) {
        throw const AuthServiceException(
          'Login failed. Please try again in a moment.',
        );
      }
      return credential;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_mapSignInError(error.code));
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) {
        throw const AuthServiceException(
          'Sign up failed. Please try again in a moment.',
        );
      }
      return credential;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_mapSignUpError(error.code));
    }
  }

  String _mapSignInError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid username and/or password. If this is your first time, please sign up.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support if this is unexpected.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  String _mapSignUpError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters and a special character.';
      case 'operation-not-allowed':
        return 'Email/password sign up is currently unavailable.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  String _mapSignOutError(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'Sign out failed due to network issues. Please try again.';
      default:
        return 'Sign out failed. Please try again.';
    }
  }
}
