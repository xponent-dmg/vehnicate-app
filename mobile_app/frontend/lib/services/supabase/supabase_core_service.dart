import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnway/utils/app_logger.dart';

class SupabaseCoreService {
  static final SupabaseCoreService _instance = SupabaseCoreService._internal();
  factory SupabaseCoreService() => _instance;
  SupabaseCoreService._internal();

  SupabaseClient? _client;

  /// Ensures the client is initialized. This should be called once in main.dart.
  static Future<void> init() async {
    await _instance.getOrInitClient();
  }

  Future<SupabaseClient> getOrInitClient() async {
    if (_client != null) return _client!;

    try {
      _client = Supabase.instance.client;
      return _client!;
    } catch (_) {
      try {
        await Supabase.initialize(
          url: dotenv.get('SUPABASE_PROD_URL'),
          anonKey: dotenv.get('SUPABASE_PROD_ANON_KEY'),
          accessToken: getFirebaseAccessToken,
        );
        _client = Supabase.instance.client;
        return _client!;
      } catch (err, stack) {
        AppLogger.error(
          'Critical: Failed to initialize Supabase client',
          err,
          stack,
        );
        FirebaseCrashlytics.instance.recordError(
          err,
          stack,
          reason: 'Supabase Initialization Failed',
        );
        throw Exception('Failed to initialize Supabase: $err');
      }
    }
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'SupabaseCoreService not initialized. Call SupabaseCoreService.init() in main.dart',
      );
    }
    return _client!;
  }

  Future<String?> getFirebaseAccessToken() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    return firebaseUser.getIdToken();
  }

  /// Returns an authenticated Supabase client with the current Firebase user's JWT.
  /// This token is used by RLS policies to verify auth.uid() server-side.
  Future<SupabaseClient> getAuthenticatedClient() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('Not authenticated: Firebase user is null');
    }

    try {
      // Ensure Supabase client is initialized with the Firebase accessToken callback.
      final client = await getOrInitClient();

      AppLogger.info(
        'Authenticated Supabase client created for user ${firebaseUser.uid}',
      );
      return client;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to create authenticated Supabase client',
        e,
        stack,
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Authenticated client creation failed',
      );
      rethrow;
    }
  }
}
