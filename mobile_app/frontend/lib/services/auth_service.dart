import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Get current user
  firebase.User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<firebase.User?> get authStateChanges => _auth.authStateChanges();

  // Reload current user
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Sign in with email and password
  Future<firebase.UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      firebase.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log analytics event for successful login
      await _analytics.logLogin(loginMethod: 'email');

      return result;
    } on firebase.FirebaseAuthException catch (e) {
      // Log analytics event for failed login
      await _analytics.logEvent(
        name: 'login_failed',
        parameters: {'method': 'email', 'error_code': e.code},
      );

      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign up with email and password
  Future<firebase.UserCredential> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      firebase.UserCredential result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Log analytics event for successful sign up
      await _analytics.logSignUp(signUpMethod: 'email');

      return result;
    } on firebase.FirebaseAuthException catch (e) {
      // Log analytics event for failed sign up
      await _analytics.logEvent(
        name: 'sign_up_failed',
        parameters: {'method': 'email', 'error_code': e.code},
      );

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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final result = await _auth.signInWithCredential(credential);

      // Create or update user in Supabase handled by UI layer after successful return

      // Log analytics event for successful Google sign in
      await _analytics.logLogin(loginMethod: 'google');

      return result;
    } on firebase.FirebaseAuthException catch (e) {
      // Log analytics event for failed Google login
      await _analytics.logEvent(
        name: 'login_failed',
        parameters: {'method': 'google', 'error_code': e.code},
      );

      throw Exception('Firebase Auth Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Log analytics event for logout
      await _analytics.logEvent(name: 'logout');

      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Debug print
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reauthenticate with Google
  Future<void> reauthenticateWithGoogle() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No current user to reauthenticate.');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
    } on firebase.FirebaseAuthException catch (e) {
      throw Exception('Failed to reauthenticate: ${_handleAuthException(e)}');
    } catch (e) {
      throw Exception('Failed to reauthenticate with Google: $e');
    }
  }

  // Reauthenticate with Email and Password
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No current user to reauthenticate.');
      if (user.email == null) throw Exception('User mapped without email.');

      final credential = firebase.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on firebase.FirebaseAuthException catch (e) {
      throw Exception('Failed to reauthenticate: ${_handleAuthException(e)}');
    } catch (e) {
      throw Exception('Failed to reauthenticate with password: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No current user to delete.');
      }

      // Refresh the Firebase user before deletion to ensure the auth session is current.
      await user.reload();

      // Delete user from Firebase Auth
      await user.delete();

      // Ensure the local Firebase and Google sessions are cleared after deletion
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Log analytics event for account deletion
      await _analytics.logEvent(name: 'account_deleted');
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Please log out and log back in before deleting your account for security reasons.',
        );
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
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
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'invalid-credential':
        // Modern Firebase Auth uses 'invalid-credential' for both wrong password
        // and non-existent user for security. We can give a slightly more tailored
        // hint if the user wants clarity.
        return 'Invalid email or password. If you don\'t have an account, please sign up.';
      case 'wrong-password':
        return 'Wrong password provided. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
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
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }
}
