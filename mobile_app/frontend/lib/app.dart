import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/dashboard/dashboard.dart';
import 'package:vehnicate_frontend/Pages/drive/drive_analyze_page.dart';
import 'package:vehnicate_frontend/Pages/profile/edit_profile_page.dart';

import 'package:vehnicate_frontend/Pages/vehicle/garage.dart';
import 'package:vehnicate_frontend/Pages/vehicle/document_upload_page.dart';
import 'package:vehnicate_frontend/Pages/auth/login_page.dart';
import 'package:vehnicate_frontend/Pages/navigation/map_page.dart';
import 'package:vehnicate_frontend/Pages/profile/profile_page.dart';
import 'package:vehnicate_frontend/Pages/onboarding/splash_page.dart';
import 'package:vehnicate_frontend/Pages/auth/signup_page.dart';
import 'package:vehnicate_frontend/Pages/drive/imu_collector_screen.dart';
import 'package:vehnicate_frontend/Pages/auth/user_details_page.dart';
import 'package:vehnicate_frontend/home.dart';

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
      routes: {
        "/splash": (context) => SplashPage(),
        "/login": (context) => LoginPage(),
        "/signup": (context) => SignupPage(),
        "/profile": (context) => ProfilePage(),
        "/dash": (context) => DashboardPage(),
        "/imu": (context) => ImuCollector(),
        "/garage": (context) => GaragePage(),
        "/analyze": (context) => DriveAnalyzePage(),
        "/editdetails": (context) => EditProfilePage(),
        "/home": (context) => Home(),
        "/map": (context) => MapPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == "/user-details") {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(builder: (context) => UserDetailsPage(userId: args["userId"], email: args["email"]));
        }
        if (settings.name == "/document-upload") {
          final args = settings.arguments as Map<String, dynamic>?;
          final docType = args != null ? (args['documentType'] as String? ?? 'Document') : 'Document';
          return MaterialPageRoute(builder: (context) => DocumentUploadPage(documentType: docType));
        }
        return null;
      },
      initialRoute: "/splash",
    );
  }
}
