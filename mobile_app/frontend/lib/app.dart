import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/dashboard.dart';
import 'package:vehnicate_frontend/Pages/drive_analyze_page.dart';

import 'package:vehnicate_frontend/Pages/garage.dart';
import 'package:vehnicate_frontend/Pages/login_page.dart';
import 'package:vehnicate_frontend/Pages/profile_page.dart';
import 'package:vehnicate_frontend/Pages/splash_page.dart';
import 'package:vehnicate_frontend/Pages/signup_page.dart';
import 'package:vehnicate_frontend/Screens/imu_collector_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    print('📱 Building App widget...');

    return MaterialApp(
      title: 'Vehnicate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple[600],
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      routes:{
        "/splash":(context)=>SplashPage(),
        "/login":(context)=>LoginPage(),
        "/signup":(context)=>SignupPage(),
        "/profile":(context)=>ProfilePage(),
        "/dash":(context)=>DashboardPage(),
        "/imu":(context)=>ImuCollector(),
        "/garage":(context)=>GaragePage(),
        "/analyze":(context)=>DriveAnalyzePage(),

      },
      initialRoute: "/splash",
    );
  }
}
