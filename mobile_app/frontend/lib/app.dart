import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehnicate_frontend/Pages/dashboard/dashboard.dart';
import 'package:vehnicate_frontend/Pages/drive/drive_analyze_page.dart';
import 'package:vehnicate_frontend/Pages/drive/drive_details_page.dart';
import 'package:vehnicate_frontend/Pages/vehicle/garage.dart';
import 'package:vehnicate_frontend/Pages/vehicle/document_upload_page.dart';
import 'package:vehnicate_frontend/Pages/auth/login_page.dart';
import 'package:vehnicate_frontend/Pages/navigation/map_page.dart';
import 'package:vehnicate_frontend/Pages/profile/profile_page.dart';
import 'package:vehnicate_frontend/Pages/onboarding/splash_page.dart';
import 'package:vehnicate_frontend/Pages/auth/signup_page.dart';
import 'package:vehnicate_frontend/Pages/auth/email_verification_page.dart';
import 'package:vehnicate_frontend/Pages/drive/imu_collector_screen.dart';
import 'package:vehnicate_frontend/Pages/auth/user_details_page.dart';
import 'package:vehnicate_frontend/Pages/vehicle/vehicle_details.dart';
import 'package:vehnicate_frontend/home.dart';
import 'package:vehnicate_frontend/models/drive_model.dart';
import 'package:vehnicate_frontend/models/vehicle_model.dart';
import 'package:vehnicate_frontend/services/page_transitions.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vehnicate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Color(0xFF555FDB),

        // primaryColor: Colors.deepPurple,
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF555FDB),
          brightness: Brightness.light,
          background: Color(0xFF2d2d44),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/splash":
            return PageTransitions.fade(SplashPage());
          case "/login":
            return PageTransitions.fade(LoginPage());
          case "/signup":
            final emailArgs = settings.arguments as String?;
            return PageTransitions.fade(SignupPage(initialEmail: emailArgs));
          case "/verify-email":
            return PageTransitions.fade(EmailVerificationPage());
          case "/profile":
            return PageTransitions.fadeSlideUp(ProfilePage());
          case "/dash":
            return PageTransitions.fade(DashboardPage());
          case "/imu":
            return PageTransitions.slideFromBottom(ImuCollector());
          case "/garage":
            return PageTransitions.scaleFade(GaragePage());
          case "/vehicle-details":
            final vehicle = settings.arguments as Vehicle?;
            return PageTransitions.slideFromBottom(VehicleDetailsPage(vehicle: vehicle!));
          case "/analyze":
            return PageTransitions.slideFromBottom(DriveAnalyzePage());
          // Edit Details - Fade + Slide Up (form-like)
          // case "/editdetails":
          //   return PageTransitions.fadeSlideUp(EditProfilePage());
          case "/home":
            return PageTransitions.fade(Home());
          case "/map":
            return PageTransitions.scaleFade(MapPage());
          case "/user-details":
            final args = settings.arguments as Map<String, dynamic>;
            return PageTransitions.slideFromRight(
              UserDetailsPage(userId: args["userId"], email: args["email"]),
            );
          case "/document-upload":
            final args = settings.arguments as Map<String, dynamic>?;
            final docType =
                args != null
                    ? (args['documentType'] as String? ?? 'Document')
                    : 'Document';
            return PageTransitions.slideFromBottom(
              DocumentUploadPage(documentType: docType),
            );
          case "/drive-details":
            final args = settings.arguments as Drive?;
            final drive = args != null ? (args as Drive?) : null;
            return PageTransitions.slideFromBottom(
              DriveDetailsPage(drive: drive!),
            );
          default:
            return null;
        }
      },
      initialRoute: "/splash",
    );
  }
}
