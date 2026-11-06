import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehnway/Pages/profile/constants/profile_constants.dart';

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
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textOffset;
  late Animation<double> _textOpacity;
  bool _showFinalText = false;
  bool _navigated = false;
  bool _animationCompleted = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _controller.forward();
        }
      });
    });
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
        _animationCompleted = true;
        _tryNavigate();
      }
    });
    _logoScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.35, curve: Curves.easeOut),
      ),
    );
    _textOffset = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );
  }

  void _tryNavigate() {
    if (!_animationCompleted) return;
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _navigated) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'assets/images/vehnway_logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 20), // spacing between image and text
              FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textOffset,
                  child: AnimatedBuilder(
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
                ),
              ),
              Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height / 3),
                child: Text(
                  "vehnicate@2026",
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
