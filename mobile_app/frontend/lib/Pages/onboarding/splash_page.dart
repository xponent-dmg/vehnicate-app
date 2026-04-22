import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const String _prefsOnboardingSeenKey = 'onboarding_seen';
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFinalText = false;
  bool _navigated = false;
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFinalText = true;
        });
        _decideNextRoute();
      }
    });
    _controller.forward();
  }

  Future<void> _decideNextRoute() async {
    await Future.delayed(Duration(milliseconds: 500));
    if (!mounted || _navigated) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_prefsOnboardingSeenKey) ?? false;

    if (!hasSeenOnboarding) {
      _navigated = true;
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    _navigated = true;
    Navigator.pushReplacementNamed(context, user != null ? '/home' : '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   colors: [const Color(0xFF000000), const Color(0xFF32055C), const Color(0xFFBE326C)],
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          // ),
          gradient: ProfileConstants.gradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // center vertically
            children: [
              Image.asset(
                'assets/images/vehnicate_logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20), // spacing between image and text
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    _showFinalText ? "vehnicate" : "vehicles+communicate",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing:
                          Tween<double>(
                            begin: 0,
                            end: -1,
                          ).animate(_animation).value,
                    ),
                  );
                },
              ),
              Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height / 3),
                child: Text(
                  "vehnicate@2025",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
