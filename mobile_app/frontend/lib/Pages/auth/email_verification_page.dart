import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/services/auth_service.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:vehnicate_frontend/Widgets/custom_dialogs.dart';
import 'package:vehnicate_frontend/utils/extensions.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = false;
  int _resendTimer = 30;
  Timer? _resendCountdownTimer;

  @override
  void initState() {
    super.initState();

    // Check if email is already verified
    isEmailVerified = AuthService().currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      // Send verification email immediately if not verified
      _sendVerificationEmail();

      // Periodically check if email is verified
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _resendCountdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    // Reload user to get latest status
    await AuthService().reloadUser();

    setState(() {
      isEmailVerified = AuthService().currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      // Wait a moment before redirecting to show success state
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        // Ensure user is verified before proceeding
        await user.reload();
        if (user.emailVerified) {
          // Explicitly create Supabase user and wait for it
          await SupabaseService().createSupabaseUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
          );
        }
      } catch (e) {
        print("Error during backend registration: $e");
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/user-details',
          (route) => false,
          arguments: {"userId": user.uid, "email": user.email ?? ""},
        );
      }
    } else {
      // Fallback
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await AuthService().sendEmailVerification();

      setState(() {
        canResendEmail = false;
        _resendTimer = 30;
      });

      // Start countdown for resend button
      _resendCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) {
        if (_resendTimer > 0) {
          setState(() {
            _resendTimer--;
          });
        } else {
          setState(() {
            canResendEmail = true;
          });
          timer.cancel();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.loc.errorSendingVerificationEmail(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleManualCheck() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              const CustomLoadingDialog(message: "Checking verification..."),
    );

    await AuthService().reloadUser();
    final verified = AuthService().currentUser?.emailVerified ?? false;

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (verified) {
        _navigateToNextScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.emailNotVerified),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2C), // Match app theme
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                context.loc.emailVerified,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.loc.redirectingToHome,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Match app theme
      appBar: AppBar(
        title: Text(context.loc.verifyEmailTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: Colors.white70,
            ),
            const SizedBox(height: 30),
            Text(
              context.loc.verifyEmailHeading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.loc.verifyEmailMessage(
                AuthService().currentUser?.email ?? "your email",
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              context.loc.verifyEmailInstruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 40),

            // Allow manual check
            ElevatedButton(
              onPressed: _handleManualCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF), // Primary color
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(context.loc.iHaveVerifiedEmail),
            ),

            const SizedBox(height: 24),

            // Resend button
            TextButton(
              onPressed: canResendEmail ? _sendVerificationEmail : null,
              child: Text(
                canResendEmail
                    ? context.loc.resendVerificationEmail
                    : context.loc.resendEmailIn(_resendTimer),
                style: TextStyle(
                  color: canResendEmail ? const Color(0xFF6C63FF) : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: Text(
                context.loc.cancelAndLogout,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
