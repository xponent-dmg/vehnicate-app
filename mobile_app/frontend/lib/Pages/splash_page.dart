import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget  {
  @override
  _SplashPageState createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to login_page after 1 second
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }
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
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center, // center vertically
            children: [
              Image.asset(
                'assets/vehnicate_logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20), // spacing between image and text
              Text(
                "vehnicate",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
             Transform.translate( 
              offset: Offset(0, MediaQuery.of(context).size.height/3),
                child:Text(
                  "vehnicate@2025",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )

      ),
    );
  }
}