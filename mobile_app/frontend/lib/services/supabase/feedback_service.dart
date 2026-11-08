import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/models/feedback_model.dart';
import 'package:vehnway/services/supabase/supabase_core_service.dart';
import 'package:vehnway/utils/app_logger.dart';

class FeedbackSubmissionResult {
  final bool isSubmitted;
  final bool emailDispatched;
  final String? feedbackId;
  final String? message;

  const FeedbackSubmissionResult({
    required this.isSubmitted,
    required this.emailDispatched,
    this.feedbackId,
    this.message,
  });
}

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final _core = SupabaseCoreService();
  final _uuid = const Uuid();

  /// Collects device hardware and operating system metadata.
  Future<Map<String, String>> getDeviceMetadata() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'Unknown Device';
    String osVersion = 'Unknown OS';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}'.trim();
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine.isNotEmpty ? iosInfo.utsname.machine : iosInfo.model;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      } else {
        deviceModel = Platform.operatingSystem;
        osVersion = Platform.operatingSystemVersion;
      }
    } catch (e, stack) {
      AppLogger.warning('Failed to gather complete device info', e, stack);
    }

    return {
      'deviceModel': deviceModel,
      'osVersion': osVersion,
    };
  }

  /// Collects application version and build number.
  Future<Map<String, String>> getAppMetadata() async {
    String appVersion = 'Unknown';
    String buildNumber = '0';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    } catch (e, stack) {
      AppLogger.warning('Failed to gather package info', e, stack);
    }

    return {
      'appVersion': appVersion,
      'buildNumber': buildNumber,
    };
  }

  /// Compresses a local image file into JPEG bytes (max 1280x1280, quality 80)
  /// to keep upload sizes small and reliable.
  Future<Uint8List> compressImage(File file) async {
    final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 1280,
      minHeight: 1280,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (compressed == null || compressed.isEmpty) {
      // Fallback to original bytes if compression is unavailable
      return await file.readAsBytes();
    }
    return compressed;
  }

  /// Submits user feedback along with optional attachments.
  ///
  /// Flow:
  /// 1. Compresses and uploads attachments to private `feedback-attachments` storage.
  /// 2. Saves record to `app_feedback` table with 'pending' email status.
  /// 3. Invokes the Edge Function `send-feedback-notification`.
  Future<FeedbackSubmissionResult> submitFeedback({
    required FeedbackCategory category,
    required String description,
    List<File> attachments = const [],
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final userId = firebaseUser?.uid;
    final submissionId = _uuid.v4();

    // 1. Obtain appropriate Supabase client
    final client = firebaseUser != null
        ? await _core.getAuthenticatedClient()
        : await _core.getOrInitClient();

    // 2. Upload attachments (if any)
    final List<String> uploadedPaths = [];
    if (attachments.isNotEmpty) {
      final userFolder = userId ?? 'anon';
      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        final ext = p.extension(file.path).replaceAll('.', '');
        final cleanExt = ext.isNotEmpty ? ext : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$cleanExt';
        final storagePath = '$userFolder/$submissionId/$fileName';

        try {
          final compressedBytes = await compressImage(file);
          await client.storage
              .from(AppConfig.bucketFeedbackAttachments)
              .uploadBinary(
                storagePath,
                compressedBytes,
                fileOptions: FileOptions(
                  contentType: 'image/${cleanExt == "png" ? "png" : "jpeg"}',
                  upsert: false,
                ),
              );
          uploadedPaths.add(storagePath);
          AppLogger.info('Uploaded feedback attachment to $storagePath');
        } catch (e, stack) {
          AppLogger.error('Failed to upload attachment $i: ${file.path}', e, stack);
          throw Exception('Failed to upload screenshot ${i + 1}: $e');
        }
      }
    }

    // 3. Collect metadata
    final appMeta = await getAppMetadata();
    final devMeta = await getDeviceMetadata();

    final feedback = FeedbackModel(
      userId: userId,
      category: category,
      description: description.trim(),
      attachmentUrls: uploadedPaths,
      appVersion: appMeta['appVersion'],
      buildNumber: appMeta['buildNumber'],
      deviceModel: devMeta['deviceModel'],
      osVersion: devMeta['osVersion'],
      status: 'new',
      emailStatus: 'pending',
    );

    // 4. Save record to database
    String? feedbackId;
    try {
      final response = await client
          .from(AppConfig.tableAppFeedback)
          .insert(feedback.toInsertMap())
          .select('id')
          .single();

      feedbackId = response['id']?.toString();
      AppLogger.info('Feedback record inserted successfully. ID: $feedbackId');
    } catch (e, stack) {
      AppLogger.error('Database insertion of feedback failed', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'App Feedback database insert failed',
      );
      throw Exception('Failed to save feedback to database: $e');
    }

    // 5. Invoke Edge Function for email dispatch
    bool emailDispatched = false;
    String? emailMessage;
    if (feedbackId != null) {
      try {
        final FunctionResponse fnResponse = await client.functions.invoke(
          'send-feedback-notification',
          body: {'feedbackId': feedbackId},
        );

        if (fnResponse.status == 200) {
          emailDispatched = true;
          AppLogger.info('Feedback notification email sent successfully.');
        } else {
          emailMessage = 'Notification queued, status ${fnResponse.status}';
          AppLogger.warning('Edge function returned status: ${fnResponse.status}');
        }
      } catch (e, stack) {
        // A failed notification should NEVER fail the user's saved submission.
        emailMessage = 'Email notification could not be dispatched: $e';
        AppLogger.warning('Edge Function invocation failed for feedback $feedbackId', e, stack);
        FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: 'Feedback Edge Function invocation failed',
        );
      }
    }

    return FeedbackSubmissionResult(
      isSubmitted: true,
      emailDispatched: emailDispatched,
      feedbackId: feedbackId,
      message: emailMessage,
    );
  }
}

