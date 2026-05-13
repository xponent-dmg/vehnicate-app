import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opsin/core/constants/app_gradients.dart';
import 'package:opsin/Pages/onboarding/onboarding_page.dart';
import 'package:opsin/Pages/onboarding/permissions_page.dart';
import 'package:provider/provider.dart';
import 'package:opsin/Pages/dashboard/dashboard.dart';
import 'package:opsin/Pages/drive/drive_analyze_page.dart';
import 'package:opsin/Pages/drive/drive_details_page.dart';
import 'package:opsin/Pages/navigation/map_webview_page.dart';
import 'package:opsin/Pages/vehicle/garage.dart';
import 'package:opsin/Pages/vehicle/document_upload_page.dart';
import 'package:opsin/Pages/auth/login_page.dart';
import 'package:opsin/Pages/navigation/map_page.dart';
import 'package:opsin/Pages/profile/profile_page.dart';
import 'package:opsin/Pages/onboarding/loading_page.dart';
import 'package:opsin/Pages/onboarding/splash_page.dart';
import 'package:opsin/Pages/onboarding/offline_page.dart';
import 'package:opsin/Pages/auth/signup_page.dart';
import 'package:opsin/Pages/auth/email_verification_page.dart';
import 'package:opsin/Pages/drive/imu_collector_screen.dart';
import 'package:opsin/Pages/auth/user_details_page.dart';
import 'package:opsin/Pages/vehicle/vehicle_details.dart';
import 'package:opsin/Providers/connectivity_provider.dart';
import 'package:opsin/home.dart';
import 'package:opsin/models/drive_model.dart';
import 'package:opsin/models/vehicle_model.dart';
import 'package:opsin/services/page_transitions.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opsin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: AppColors.primary,

        // primaryColor: Colors.deepPurple,
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          background: AppColors.background,
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
      builder: (context, child) => ConnectivityWrapper(child: child!),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/splash":
            return PageTransitions.fade(SplashPage());
          case "/onboarding":
            return PageTransitions.slideFromRight(OnboardingPage());
          case "/permissions":
            return PageTransitions.slideFromRight(PermissionsPage());
          case "/login":
            final emailArgs = settings.arguments as String?;
            return PageTransitions.fade(LoginPage(initialEmail: emailArgs));
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
            return PageTransitions.slideFromBottom(
              VehicleDetailsPage(vehicle: vehicle!),
            );
          case "/analyze":
            return PageTransitions.slideFromBottom(DriveAnalyzePage());
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
          case "/loading":
            final args = settings.arguments as Map<String, dynamic>?;
            final duration =
                args?['duration'] as Duration? ?? const Duration(seconds: 3);
            final onComplete = args?['onComplete'] as VoidCallback?;
            return PageTransitions.fade(
              LoadingPage(duration: duration, onComplete: onComplete),
            );
          case "/drive-details":
            final args = settings.arguments as Drive?;
            final drive = args != null ? (args as Drive?) : null;
            return PageTransitions.slideFromBottom(
              DriveDetailsPage(drive: drive!),
            );

          case "/map-webview":
            return PageTransitions.slideFromBottom(MapWebviewScreen());
          default:
            return null;
        }
      },
      initialRoute: "/splash",
    );
  }
}

// ─── Connectivity Wrapper ─────────────────────────────────────────────────────

/// Sits between [MaterialApp] and every navigated page via the `builder`
/// parameter. It listens to [ConnectivityProvider] and slides [OfflinePage]
/// over the current content whenever the device goes offline, then slides it
/// away again when connectivity is restored.
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<ConnectivityProvider, bool>(
      (p) => p.isOnline,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder:
          (widget, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: widget,
            ),
          ),
      child:
          isOnline
              ? KeyedSubtree(key: const ValueKey('online'), child: child)
              : KeyedSubtree(
                key: const ValueKey('offline'),
                child: OfflinePage(
                  onRetry: () => context.read<ConnectivityProvider>().recheck(),
                ),
              ),
    );
  }
}
