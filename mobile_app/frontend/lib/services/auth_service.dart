import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      print('Attempting email sign in for: $email');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Log analytics event for successful login
      await _analytics.logLogin(loginMethod: 'email');
      
      print('Email sign in successful');
      return result;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      
      // Log analytics event for failed login
      await _analytics.logEvent(
        name: 'login_failed',
        parameters: {
          'method': 'email',
          'error_code': e.code,
        },
      );
      
      throw _handleAuthException(e);
    } catch (e) {
      print('General sign in error: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Log analytics event for successful sign up
      await _analytics.logSignUp(signUpMethod: 'email');
      
      return result;
    } on FirebaseAuthException catch (e) {
      // Log analytics event for failed sign up
      await _analytics.logEvent(
        name: 'sign_up_failed',
        parameters: {
          'method': 'email',
          'error_code': e.code,
        },
      );
      
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('Starting Google sign in...');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google sign in was cancelled by user');
        throw Exception('Google sign in was cancelled');
      }

      print('Google user obtained: ${googleUser.email}');
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Google auth tokens obtained');
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Firebase credential created, signing in...');
      // Once signed in, return the UserCredential
      final result = await _auth.signInWithCredential(credential);
      
      // Log analytics event for successful Google sign in
      await _analytics.logLogin(loginMethod: 'google');
      
      print('Google sign in successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during Google sign in: ${e.code} - ${e.message}');
      
      // Log analytics event for failed Google login
      await _analytics.logEvent(
        name: 'login_failed',
        parameters: {
          'method': 'google',
          'error_code': e.code,
        },
      );
      
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
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
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
