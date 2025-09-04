import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Get current user
  firebase.User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<firebase.User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<firebase.UserCredential> signInWithEmail(String email, String password) async {
    try {
      print('Attempting email sign in for: $email');
      firebase.UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Log analytics event for successful login
      await _analytics.logLogin(loginMethod: 'email');

      print('Email sign in successful');
      return result;
    } on firebase.FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');

      // Log analytics event for failed login
      await _analytics.logEvent(name: 'login_failed', parameters: {'method': 'email', 'error_code': e.code});

      throw _handleAuthException(e);
    } catch (e) {
      print('General sign in error: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign up with email and password
  Future<firebase.UserCredential> signUpWithEmail(String email, String password) async {
    try {
      firebase.UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Log analytics event for successful sign up
      await _analytics.logSignUp(signUpMethod: 'email');

      return result;
    } on firebase.FirebaseAuthException catch (e) {
      // Log analytics event for failed sign up
      await _analytics.logEvent(name: 'sign_up_failed', parameters: {'method': 'email', 'error_code': e.code});

      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<firebase.UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Google auth tokens obtained');
      // Create a new credential
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final result = await _auth.signInWithCredential(credential);

      // Create or update user in Supabase
      if (result.user != null) {
        try {
          final supabase = Supabase.instance.client;
          
          // Check if user exists in Supabase
          final existingUser = await supabase
              .from('userdetails')
              .select()
              .eq('firebaseuid', result.user!.uid)
              .maybeSingle();

          if (existingUser == null) {
            // Create new user in Supabase
            await supabase.from('userdetails').insert({
              'firebaseuid': result.user!.uid,
              'email': result.user!.email,
              'name': result.user!.displayName ?? 'New User',
              'username': result.user!.displayName?.split(' ')[0] ?? 'New User',
              'created_at': DateTime.now().toIso8601String(),
              'role': 'User',
            });
            print('Created new user in Supabase');
          } else {
            print('User already exists in Supabase');
          }
        } catch (e) {
          print('Error creating/updating Supabase user: $e');
          // Don't throw the error as Firebase auth was successful
        }
      }

      // Log analytics event for successful Google sign in
      await _analytics.logLogin(loginMethod: 'google');

      print('Google sign in successful: ${result.user?.email}');
      return result;
    } on firebase.FirebaseAuthException catch (e) {
      print('FirebaseAuthException during Google sign in: ${e.code} - ${e.message}');

      // Log analytics event for failed Google login
      await _analytics.logEvent(name: 'login_failed', parameters: {'method': 'google', 'error_code': e.code});

      throw Exception('Firebase Auth Error: ${e.message}');
    } catch (e) {
      print('General Google sign in error: $e');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Starting signOut process');

      // Log analytics event for logout
      await _analytics.logEvent(name: 'logout');

      await _googleSignIn.signOut();
      print('Google sign out completed');
      await _auth.signOut();
      print('Firebase auth sign out completed');
    } catch (e) {
      print('SignOut error: $e'); // Debug print
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(firebase.FirebaseAuthException e) {
    print('Handling Firebase Auth Exception: ${e.code}');
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'internal-error':
        return 'Internal server error. Please try again later.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return 'An error occurred: ${e.message ?? e.code}';
    }
  }
}
