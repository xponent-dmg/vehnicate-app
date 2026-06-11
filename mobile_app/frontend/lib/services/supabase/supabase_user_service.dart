import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/utils/app_logger.dart';

import 'supabase_core_service.dart';

class SupabaseUserService {
  static final SupabaseUserService _instance = SupabaseUserService._internal();
  factory SupabaseUserService() => _instance;
  SupabaseUserService._internal();

  final _core = SupabaseCoreService();

  Future<void> registerUser({
    required String uid,
    required String email,
    required String password,
  }) async {
    try {
      await _core.getOrInitClient();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String username,
    String? phone,
    String? address,
    String? profilePictureUrl,
  }) async {
    try {
      final client = await _core.getAuthenticatedClient();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Not authenticated: Firebase user is null');
      }

      final Map<String, dynamic> updateData = {
        'name': fullName,
        'username': username,
      };

      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (profilePictureUrl != null) {
        updateData['profile_picture_url'] = profilePictureUrl;
      }

      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .update(updateData)
              .eq('firebaseuid', firebaseUser.uid)
              .select();

      if ((response as List).isEmpty) {
        throw Exception('User record not found or RLS policy blocked update');
      }
      AppLogger.info('User profile updated successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to update profile', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'User profile update failed',
      );
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<String> uploadProfilePicture(File file, String userId) async {
    try {
      final client = await _core.getOrInitClient();

      final fileExt = file.path.split('.').last;
      final fileName =
          '${userId}_${DateTime.now().toLocal().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await client.storage
          .from(AppConfig.bucketUserAvatars)
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = client.storage
          .from(AppConfig.bucketUserAvatars)
          .getPublicUrl(filePath);

      AppLogger.info('Profile picture uploaded successfully for $userId');
      return imageUrl;
    } catch (e, stack) {
      AppLogger.error('Failed to upload profile picture for $userId', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Profile picture upload failed',
      );
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserdetails() async {
    try {
      final client = await _core.getAuthenticatedClient();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Not authenticated: Firebase user is null');
      }

      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', firebaseUser.uid)
              .maybeSingle();

      return response;
    } catch (e, stack) {
      AppLogger.warning('Error fetching user details', e, stack);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrCreateUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      final client = await _core.getAuthenticatedClient();

      final existingUser =
          await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', uid)
              .maybeSingle();

      if (existingUser != null) {
        return existingUser;
      }

      final name = displayName ?? 'New User';
      final username = name.split(' ')[0];

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase user is null during user creation');
      }

      final newData = {
        'firebaseuid': firebaseUser.uid,
        'email': email,
        'name': name,
        'username': username,
      };

      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .insert(newData)
              .select()
              .single();

      AppLogger.info('New user record created in Supabase for $uid');
      return response;
    } catch (e, stack) {
      if (e is PostgrestException && e.code == '23505') {
        AppLogger.info(
          'Conflict (23505) in getOrCreateUser for $uid. Retrying select...',
        );
        try {
          final client = await _core.getAuthenticatedClient();
          final existingUser =
              await client
                  .from(AppConfig.tableUserDetails)
                  .select()
                  .eq('firebaseuid', uid)
                  .maybeSingle();
          if (existingUser != null) {
            return existingUser;
          }
        } catch (retryError, retryStack) {
          AppLogger.error(
            'Failed to refetch user after conflict',
            retryError,
            retryStack,
          );
        }
      }

      AppLogger.error('Error in getOrCreateUser for $uid', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'getOrCreateUser failed',
      );
      return null;
    }
  }

  Future<void> ensureUserExists({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    await getOrCreateUser(uid: uid, email: email, displayName: displayName);
  }

  Future<void> deleteUser() async {
    try {
      final client = await _core.getAuthenticatedClient();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Not authenticated: Firebase user is null');
      }

      final checkUser =
          await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', firebaseUser.uid)
              .maybeSingle();

      if (checkUser == null) {
        return;
      }

      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .delete()
              .eq('firebaseuid', firebaseUser.uid)
              .select();

      if ((response as List).isEmpty) {
        throw Exception(
          "Supabase RLS Error: Your Supabase database is blocking account deletion. Check your DELETE policy on 'user_details'.",
        );
      }
      AppLogger.info('User deleted successfully from Supabase');
    } catch (e, stack) {
      AppLogger.error('Failed to delete Supabase user', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Account deletion failed',
      );
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final client = await _core.getAuthenticatedClient();
      final response =
          await client
              .from(AppConfig.tableUserDetails)
              .select('username')
              .eq('username', username)
              .maybeSingle();
      return response == null;
    } catch (e, stack) {
      AppLogger.warning(
        'Error checking username availability for $username',
        e,
        stack,
      );
      throw Exception('Failed to check username availability: $e');
    }
  }
}
