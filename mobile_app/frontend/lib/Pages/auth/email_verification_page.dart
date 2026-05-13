import 'dart:async';
import 'package:flutter/material.dart';
import 'package:opsin/Widgets/custom_snackbar.dart';
import 'package:opsin/services/auth_service.dart';
import 'package:opsin/services/supabase_service.dart';
import 'package:opsin/Widgets/custom_dialogs.dart';
import 'package:opsin/core/constants/app_gradients.dart';

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
          await SupabaseService().ensureUserExists(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(context, "Error checking verification: $e");
        }
        return;
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
            content: Text("Error sending verification email: $e"),
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
          const SnackBar(
            content: Text("Email not verified yet. Please check your inbox."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService().currentUser?.email ?? 'your email';

    // ── Success state ─────────────────────────────────────────────────────────
    if (isEmailVerified) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.deepBlueBackground, Color(0xFF16213e), Color(0xFF0f3460)],
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 80,
                    color: AppColors.buttonBlue,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Email verified!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Taking you to the app…',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Pending verification state ────────────────────────────────────────────
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.deepBlueBackground, Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 50,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 32),

                // Headline
                const Text(
                  'Check your inbox',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Email address pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Single calm instruction line
                const Text(
                  'Click the link in the email to verify your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtle tip — italic, smaller
                const Text(
                  'If you sent multiple emails, use the latest one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 40),

                // Primary CTA — full width, matches login/signup style
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleManualCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF), // 1mary color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'I\'ve verified my email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Cancel (left) & Resend (right) — side by side
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (r) => false);
                        }
                      },
                      child: const Text(
                        'Cancel & Log Out',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    TextButton(
                      onPressed: canResendEmail ? _sendVerificationEmail : null,
                      child: Text(
                        canResendEmail
                            ? 'Resend email'
                            : 'Resend in ${_resendTimer}s',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              canResendEmail
                                  ? const Color(0xFF6C63FF)
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
