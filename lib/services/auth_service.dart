import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // For web, use Firebase's native popup provider which works better with GIS
        final googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      }

      // Mobile / Desktop flow using google_sign_in package
      // 1. Authenticate (Identity) - returns GoogleSignInAccount or throws
      final googleUser = await _googleSignIn.authenticate();
      
      // 2. Get Authentication details (for idToken)
      // In version 7.x, this is a synchronous property
      final googleAuth = googleUser.authentication;

      // 3. Get Authorization (for accessToken)
      // In version 7.x, accessToken must be obtained via authorizationClient
      final authorizedUser = await googleUser.authorizationClient.authorizeScopes(['email', 'openid']);
      final String accessToken = authorizedUser.accessToken;

      // 4. Create Firebase Credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw const AuthServiceException(
          'Google Sign-in failed. Please try again.',
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_mapSignInError(error.code));
    } catch (error) {
      if (error is AuthServiceException) rethrow;
      // Provide more context for the "unexpected" error to help debugging
      throw AuthServiceException(
        'An unexpected error occurred during Google Sign-in: ${error.toString()}',
      );
    }
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
}
