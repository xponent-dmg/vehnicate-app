import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:opsin/Providers/user_provider.dart';
import 'package:opsin/Providers/vehicle_provider.dart';
import 'package:opsin/Providers/connectivity_provider.dart';
import 'package:opsin/app.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:opsin/services/cache_service.dart';
import 'package:opsin/services/supabase_service.dart';
import 'package:opsin/utils/app_logger.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await CacheService().init();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await dotenv.load(fileName: ".env");
    _validateEnv();

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.get('FIREBASE_API_KEY'),
        appId: dotenv.get('FIREBASE_APP_ID'),
        messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: dotenv.get('FIREBASE_PROJECT_ID'),
      ),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Firebase initialization timed out');
      },
    );

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      AppLogger.error('Unhandled Global Error', error, stack);
      return true;
    };

    await SupabaseService.init().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Supabase initialization timed out');
      },
    );

    AppLogger.info('App initialized successfully');
  } catch (e, stack) {
    AppLogger.error('Initialization failed', e, stack);
    // In production, we might want to show an error screen here.
    // For now, we allow the app to run (it will likely fail later on service calls),
    // but the error is recorded.
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
      ],
      child: const App(),
    ),
  );
}

void _validateEnv() {
  const criticalKeys = [
    'FIREBASE_API_KEY',
    'FIREBASE_APP_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
    'FIREBASE_PROJECT_ID',
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
  ];

  final missingKeys =
      criticalKeys.where((key) => !dotenv.env.containsKey(key)).toList();

  if (missingKeys.isNotEmpty) {
    final errorMsg =
        'Missing critical environment variables: ${missingKeys.join(', ')}';
    AppLogger.error(errorMsg, null, null);
    throw Exception(errorMsg);
  }
}
