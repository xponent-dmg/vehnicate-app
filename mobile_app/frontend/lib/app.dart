import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/dashboard/dashboard.dart';
import 'package:vehnicate_frontend/Pages/drive/drive_analyze_page.dart';
import 'package:vehnicate_frontend/Pages/drive/drive_details_page.dart';
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
import 'package:vehnicate_frontend/models/drive_model.dart';
import 'package:vehnicate_frontend/services/page_transitions.dart';

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
      onGenerateRoute: (settings) {
        // Apply custom transitions to all routes
        switch (settings.name) {
          // Splash and Auth - Fade transition (clean and simple)
          case "/splash":
            return PageTransitions.fade(SplashPage());
          case "/login":
            return PageTransitions.fade(LoginPage());
          case "/signup":
            return PageTransitions.fade(SignupPage());

          // Profile - Fade + Slide Up (elegant)
          case "/profile":
            return PageTransitions.fadeSlideUp(ProfilePage());

          // Dashboard - Fade (quick and clean)
          case "/dash":
            return PageTransitions.fade(DashboardPage());

          // IMU Collector - Slide from Bottom (modal-style)
          case "/imu":
            return PageTransitions.slideFromBottom(ImuCollector());

          // Garage - Scale + Fade (emphasis)
          case "/garage":
            return PageTransitions.scaleFade(GaragePage());

          // Drive Analyze - Slide from Right (forward navigation)
          case "/analyze":
            return PageTransitions.slideFromRight(DriveAnalyzePage());

          // Edit Details - Fade + Slide Up (form-like)
          case "/editdetails":
            return PageTransitions.fadeSlideUp(EditProfilePage());

          // Home - Fade (neutral)
          case "/home":
            return PageTransitions.fade(Home());

          // Map - Scale + Fade (focus on map)
          case "/map":
            return PageTransitions.scaleFade(MapPage());

          // User Details with arguments
          case "/user-details":
            final args = settings.arguments as Map<String, dynamic>;
            return PageTransitions.slideFromRight(UserDetailsPage(userId: args["userId"], email: args["email"]));

          // Document Upload with arguments
          case "/document-upload":
            final args = settings.arguments as Map<String, dynamic>?;
            final docType = args != null ? (args['documentType'] as String? ?? 'Document') : 'Document';
            return PageTransitions.slideFromBottom(DocumentUploadPage(documentType: docType));

          case "/drive-details":
            final args = settings.arguments as Drive?;
            final drive = args != null ? (args as Drive?) : null;
            return PageTransitions.slideFromRight(DriveDetailsPage(drive: drive!));

          default:
            return null;
        }
      },
      initialRoute: "/splash",
    );
  }
}
