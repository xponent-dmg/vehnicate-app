import 'dart:io';
import 'dart:math';
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

      // 1. Check if user already exists by firebaseuid
      final existingByUid =
          await client
              .from(AppConfig.tableUserDetails)
              .select()
              .eq('firebaseuid', uid)
              .maybeSingle();

      if (existingByUid != null) {
        return existingByUid;
      }

      // 2. Check if user already exists by email
      if (email.isNotEmpty) {
        final existingByEmail =
            await client
                .from(AppConfig.tableUserDetails)
                .select()
                .eq('email', email)
                .maybeSingle();

        if (existingByEmail != null) {
          // If the record has a different/outdated firebaseuid (e.g. recreated in Firebase test project),
          // update the firebaseuid to link it to the current Firebase user.
          if (existingByEmail['firebaseuid'] != uid) {
            try {
              final updated =
                  await client
                      .from(AppConfig.tableUserDetails)
                      .update({'firebaseuid': uid})
                      .eq('email', email)
                      .select()
                      .single();
              AppLogger.info(
                'Updated existing user with email $email to new firebaseuid $uid',
              );
              return updated;
            } catch (updateErr) {
              AppLogger.warning(
                'Could not update firebaseuid for existing email $email: $updateErr',
              );
            }
          }
          return existingByEmail;
        }
      }

      final name = displayName ?? 'New User';
      final usernameBase = _buildUsernameBase(name);
      final usernameCandidates = _buildUsernameCandidates(
        usernameBase: usernameBase,
        uid: uid,
      );

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase user is null during user creation');
      }

      for (final username in usernameCandidates) {
        final newData = {
          'firebaseuid': firebaseUser.uid,
          'email': email,
          'name': name,
          'username': username,
        };

        try {
          final response =
              await client
                  .from(AppConfig.tableUserDetails)
                  .insert(newData)
                  .select()
                  .single();

          AppLogger.info('New user record created in Supabase for $uid');
          return response;
        } on PostgrestException catch (insertError, insertStack) {
          if (insertError.code == '23505') {
            // Check by firebaseuid
            final existingAfterConflict = await client
                .from(AppConfig.tableUserDetails)
                .select()
                .eq('firebaseuid', uid)
                .maybeSingle();

            if (existingAfterConflict != null) {
              AppLogger.info(
                'Existing user row found by uid after conflict while creating $uid',
              );
              return existingAfterConflict;
            }

            // Check by email (e.g., userdetails_email_key violation)
            if (email.isNotEmpty) {
              final existingByEmailAfterConflict = await client
                  .from(AppConfig.tableUserDetails)
                  .select()
                  .eq('email', email)
                  .maybeSingle();

              if (existingByEmailAfterConflict != null) {
                AppLogger.info(
                  'Existing user row found by email after conflict while creating $uid',
                );
                if (existingByEmailAfterConflict['firebaseuid'] != uid) {
                  try {
                    final updated =
                        await client
                            .from(AppConfig.tableUserDetails)
                            .update({'firebaseuid': uid})
                            .eq('email', email)
                            .select()
                            .single();
                    return updated;
                  } catch (_) {}
                }
                return existingByEmailAfterConflict;
              }
            }

            AppLogger.warning(
              'Conflict (23505) while creating user $uid with username $username',
              insertError,
              insertStack,
            );
            continue;
          }
          rethrow;
        }
      }

      final existingAfterRetries = await client
          .from(AppConfig.tableUserDetails)
          .select()
          .eq('firebaseuid', uid)
          .maybeSingle();
      if (existingAfterRetries != null) {
        return existingAfterRetries;
      }

      if (email.isNotEmpty) {
        final existingByEmail = await client
            .from(AppConfig.tableUserDetails)
            .select()
            .eq('email', email)
            .maybeSingle();
        if (existingByEmail != null) {
          return existingByEmail;
        }
      }

      throw Exception(
        'Failed to create user_details after trying multiple username candidates.',
      );
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
          if (email.isNotEmpty) {
            final existingByEmail =
                await client
                    .from(AppConfig.tableUserDetails)
                    .select()
                    .eq('email', email)
                    .maybeSingle();
            if (existingByEmail != null) {
              return existingByEmail;
            }
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

  String _buildUsernameBase(String name) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (normalized.isEmpty) {
      return 'new_user';
    }

    final firstToken = normalized.split('_').first;
    return firstToken.isEmpty ? 'new_user' : firstToken;
  }

  List<String> _buildUsernameCandidates({
    required String usernameBase,
    required String uid,
  }) {
    final uidSuffix = uid.length >= 6 ? uid.substring(uid.length - 6) : uid;
    final randomSuffix = Random().nextInt(10000).toString().padLeft(4, '0');

    return [
      usernameBase,
      '${usernameBase}_$uidSuffix',
      '${usernameBase}_${uidSuffix}_$randomSuffix',
    ];
  }

  Future<void> ensureUserExists({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final result = await getOrCreateUser(
      uid: uid,
      email: email,
      displayName: displayName,
    );
    if (result == null) {
      throw Exception(
        'Could not load or initialize user account in database. Please try again.',
      );
    }
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
