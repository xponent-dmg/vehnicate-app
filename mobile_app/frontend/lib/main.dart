import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/user_provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Providers/connectivity_provider.dart';
import 'package:vehnway/Providers/imu_collection_controller.dart';
import 'package:vehnway/Providers/road_report_provider.dart';
import 'package:vehnway/app.dart';
import 'package:vehnway/services/cache_service.dart';
import 'package:vehnway/services/daily_reminder_service.dart';
import 'package:vehnway/services/foreground_collection_service.dart';
import 'package:vehnway/services/supabase/supabase_core_service.dart';
import 'package:vehnway/utils/app_logger.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await _initializeServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ImuCollectionController()),
        ChangeNotifierProvider(create: (_) => RoadReportProvider()),
      ],
      child: const App(),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    ForegroundCollectionService.initialize();
    await DailyReminderService.initialize();

    await Hive.initFlutter();
    await CacheService().init();

    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'prod',
    );
    AppLogger.info('Active Environment: $environment');
    await dotenv.load(fileName: '.env.$environment');
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
      onTimeout:
          () => throw TimeoutException('Firebase initialization timed out'),
    );

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      AppLogger.error('Unhandled Global Error', error, stack);
      return true;
    };

    await SupabaseCoreService.init().timeout(
      const Duration(seconds: 15),
      onTimeout:
          () => throw TimeoutException('Supabase initialization timed out'),
    );
    AppLogger.info('App initialized successfully');
  } catch (error, stackTrace) {
    AppLogger.error('Initialization failed', error, stackTrace);
  }
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
    throw Exception(
      'Missing critical environment variables: ${missingKeys.join(', ')}',
    );
  }
}
