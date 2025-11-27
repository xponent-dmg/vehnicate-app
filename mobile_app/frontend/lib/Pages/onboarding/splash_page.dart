import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFinalText = false;
  bool _navigated = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 1500), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showFinalText = true;
          });
          // Decide route after animation completes
          Future.delayed(Duration(milliseconds: 500), () {
            if (_navigated) return;
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              _navigated = true;
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              _navigated = true;
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF000000), const Color(0xFF32055C), const Color(0xFFBE326C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // center vertically
            children: [
              Image.asset('assets/vehnicate_logo.png', width: 150, height: 150, fit: BoxFit.contain),
              SizedBox(height: 20), // spacing between image and text
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    _showFinalText ? "Vehnicate" : "Vehicle + Communicate",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: Tween<double>(begin: 0, end: -1).animate(_animation).value,
                    ),
                  );
                },
              ),
              Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height / 3),
                child: Text(
                  "Vehnicate@2025",
                  style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
