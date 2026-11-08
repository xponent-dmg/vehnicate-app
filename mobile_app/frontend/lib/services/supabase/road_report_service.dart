import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vehnway/core/constants/app_config.dart';
import 'package:vehnway/models/road_report_model.dart';
import 'package:vehnway/services/supabase/supabase_core_service.dart';
import 'package:vehnway/utils/app_logger.dart';

class RoadReportService {
  static final RoadReportService _instance = RoadReportService._internal();
  factory RoadReportService() => _instance;
  RoadReportService._internal();

  final _core = SupabaseCoreService();
  final _uuid = const Uuid();

  // In-memory cache for signed URLs (path -> {url, expiresAt})
  final Map<String, ({String url, DateTime expiresAt})> _signedUrlCache = {};

  /// Compresses a local image file into JPEG bytes (max 1280x1280, quality 80)
  Future<Uint8List> compressImage(File file) async {
    try {
      final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 1280,
        minHeight: 1280,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (compressed != null && compressed.isNotEmpty) {
        return compressed;
      }
    } catch (e, stack) {
      AppLogger.warning('Image compression failed, using original bytes', e, stack);
    }
    return await file.readAsBytes();
  }

  /// Obtains a signed URL for private storage paths, using memory cache
  Future<String?> getSignedImageUrl(String storagePath, {int expiresIn = 3600}) async {
    if (storagePath.isEmpty) return null;

    final cached = _signedUrlCache[storagePath];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return cached.url;
    }

    try {
      final client = await _core.getAuthenticatedClient();
      final signedUrl = await client.storage
          .from(AppConfig.bucketRoadReportMedia)
          .createSignedUrl(storagePath, expiresIn);

      _signedUrlCache[storagePath] = (
        url: signedUrl,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
      return signedUrl;
    } catch (e, stack) {
      AppLogger.warning('Failed to generate signed URL for $storagePath', e, stack);
      return null;
    }
  }

  /// Fetches nearby road reports using PostGIS ST_DWithin RPC
  Future<List<RoadReport>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusMeters = 2000.0,
    String? categoryFilter,
    String? statusFilter,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final client = await _core.getAuthenticatedClient();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      final response = await client.rpc('get_nearby_road_reports', params: {
        'user_lat': latitude,
        'user_lon': longitude,
        'radius_meters': radiusMeters,
        'category_filter': categoryFilter,
        'status_filter': statusFilter,
        'current_user_id': currentUserId,
        'limit_count': limit,
        'offset_count': offset,
      });

      if (response is List) {
        return response
            .map((item) => RoadReport.fromRpcMap(
                  Map<String, dynamic>.from(item),
                  currentUserId: currentUserId,
                ))
            .toList();
      }
      return [];
    } catch (e, stack) {
      AppLogger.error('Failed to get nearby road reports', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Get nearby road reports failed',
      );
      rethrow;
    }
  }

  /// Fetches a single road report with details
  Future<RoadReport?> getReportById(String reportId, {double? userLat, double? userLon}) async {
    try {
      final client = await _core.getAuthenticatedClient();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      final reportData = await client
          .from(AppConfig.tableRoadReports)
          .select()
          .eq('id', reportId)
          .maybeSingle();

      if (reportData == null) return null;

      // Fetch media paths
      final mediaData = await client
          .from(AppConfig.tableRoadReportMedia)
          .select('storage_path')
          .eq('report_id', reportId)
          .order('created_at', ascending: true);

      final mediaPaths = (mediaData as List)
          .map((m) => m['storage_path']?.toString() ?? '')
          .where((p) => p.isNotEmpty)
          .toList();

      // Fetch verifications
      final verificationsData = await client
          .from(AppConfig.tableRoadReportVerifications)
          .select('verdict, user_id')
          .eq('report_id', reportId);

      int present = 0;
      int repaired = 0;
      int incorrect = 0;
      VerificationVerdict? userVerdict;

      for (var v in verificationsData as List) {
        final verdictStr = v['verdict']?.toString();
        final vUserId = v['user_id']?.toString();
        if (verdictStr == 'present') present++;
        if (verdictStr == 'repaired') repaired++;
        if (verdictStr == 'incorrect') incorrect++;
        if (currentUserId != null && vUserId == currentUserId && verdictStr != null) {
          userVerdict = VerificationVerdict.fromValue(verdictStr);
        }
      }

      return RoadReport.fromTableMap(
        reportData,
        mediaPaths: mediaPaths,
        counts: {'present': present, 'repaired': repaired, 'incorrect': incorrect},
        userVerdict: userVerdict,
        currentUserId: currentUserId,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get road report by ID $reportId', e, stack);
      rethrow;
    }
  }

  /// Creates a new road report and uploads 1-3 photographs
  Future<RoadReport> createRoadReport({
    required RoadReportCategory category,
    required double latitude,
    required double longitude,
    double? locationAccuracy,
    RoadReportSeverity? severity,
    String? description,
    required List<File> imageFiles,
    String? sourceTripId,
    void Function(double progress)? onProgress,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('User must be authenticated to submit road reports');
    }

    if (imageFiles.isEmpty) {
      throw Exception('At least one photograph is required as evidence');
    }

    final client = await _core.getAuthenticatedClient();
    final userId = firebaseUser.uid;
    final reportId = _uuid.v4();
    final List<String> uploadedPaths = [];

    try {
      final totalImages = imageFiles.length;
      // 1. Upload each compressed image
      for (int i = 0; i < totalImages; i++) {
        final file = imageFiles[i];
        final ext = p.extension(file.path).replaceAll('.', '');
        final cleanExt = ext.isNotEmpty ? ext : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$cleanExt';
        final storagePath = '$userId/$reportId/$fileName';

        final compressedBytes = await compressImage(file);

        await client.storage
            .from(AppConfig.bucketRoadReportMedia)
            .uploadBinary(
              storagePath,
              compressedBytes,
              fileOptions: FileOptions(
                contentType: 'image/${cleanExt == "png" ? "png" : "jpeg"}',
                upsert: false,
              ),
            );

        uploadedPaths.add(storagePath);
        onProgress?.call((i + 1) / (totalImages + 1));
      }

      // 2. Insert road_report record
      final insertData = {
        'id': reportId,
        'user_id': userId,
        'issue_type': category.value,
        'latitude': latitude,
        'longitude': longitude,
        if (locationAccuracy != null) 'location_accuracy': locationAccuracy,
        if (severity != null) 'severity': severity.value,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'status': 'pending',
        if (sourceTripId != null) 'source_trip_id': sourceTripId,
      };

      await client.from(AppConfig.tableRoadReports).insert(insertData);

      // 3. Insert media records
      final mediaRows = uploadedPaths.map((path) => {
        'report_id': reportId,
        'storage_path': path,
        'media_type': 'image/jpeg',
      }).toList();

      await client.from(AppConfig.tableRoadReportMedia).insert(mediaRows);
      onProgress?.call(1.0);

      AppLogger.info('Road report $reportId created with ${uploadedPaths.length} photos');

      return RoadReport(
        id: reportId,
        userId: userId,
        category: category,
        latitude: latitude,
        longitude: longitude,
        locationAccuracy: locationAccuracy,
        severity: severity,
        description: description?.trim(),
        status: RoadReportStatus.pending,
        sourceTripId: sourceTripId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mediaStoragePaths: uploadedPaths,
        isOwnReport: true,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to create road report $reportId', e, stack);
      // Clean up uploaded files in case of DB failure to avoid orphaned storage
      for (final path in uploadedPaths) {
        try {
          await client.storage.from(AppConfig.bucketRoadReportMedia).remove([path]);
        } catch (_) {}
      }
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Road report creation failed',
      );
      rethrow;
    }
  }

  /// Submits an observational verification on an existing road report
  Future<void> submitVerification({
    required String reportId,
    required VerificationVerdict verdict,
    String? description,
    File? evidencePhoto,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('User must be authenticated to submit verifications');
    }

    final client = await _core.getAuthenticatedClient();
    final userId = firebaseUser.uid;
    String? evidencePath;

    try {
      // 1. Upload verification photo if provided
      if (evidencePhoto != null) {
        final ext = p.extension(evidencePhoto.path).replaceAll('.', '');
        final cleanExt = ext.isNotEmpty ? ext : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_verification.$cleanExt';
        evidencePath = '$userId/verifications/$reportId/$fileName';

        final compressedBytes = await compressImage(evidencePhoto);
        await client.storage
            .from(AppConfig.bucketRoadReportMedia)
            .uploadBinary(
              evidencePath,
              compressedBytes,
              fileOptions: FileOptions(
                contentType: 'image/${cleanExt == "png" ? "png" : "jpeg"}',
                upsert: false,
              ),
            );
      }

      // 2. Insert or upsert verification record
      final verificationData = {
        'report_id': reportId,
        'user_id': userId,
        'verdict': verdict.value,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (evidencePath != null) 'evidence_storage_path': evidencePath,
      };

      await client.from(AppConfig.tableRoadReportVerifications).upsert(
        verificationData,
        onConflict: 'report_id,user_id',
      );

      AppLogger.info('User $userId verified report $reportId with verdict ${verdict.value}');
    } catch (e, stack) {
      AppLogger.error('Failed to submit verification for report $reportId', e, stack);
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Verification submission failed',
      );
      rethrow;
    }
  }

  /// Fetches contribution statistics for the current user
  Future<UserContributionStats> getUserContributionStats() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const UserContributionStats(reportedCount: 0, verifiedCount: 0);
    }

    try {
      final client = await _core.getAuthenticatedClient();
      final response = await client.rpc('get_user_contribution_stats', params: {
        'target_user_id': firebaseUser.uid,
      });

      if (response is List && response.isNotEmpty) {
        final row = response.first;
        return UserContributionStats(
          reportedCount: (row['reported_count'] as num?)?.toInt() ?? 0,
          verifiedCount: (row['verified_count'] as num?)?.toInt() ?? 0,
        );
      }
      return const UserContributionStats(reportedCount: 0, verifiedCount: 0);
    } catch (e, stack) {
      AppLogger.error('Failed to fetch contribution stats', e, stack);
      return const UserContributionStats(reportedCount: 0, verifiedCount: 0);
    }
  }

  /// Fetches user contribution activities with filtering and pagination
  Future<List<ContributionActivity>> getUserContributionActivities({
    ContributionActivityType? activityFilter,
    RoadReportCategory? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return [];

    try {
      final client = await _core.getAuthenticatedClient();
      final userId = firebaseUser.uid;
      final List<ContributionActivity> activities = [];

      // Fetch user's reports if filter allows
      if (activityFilter == null || activityFilter == ContributionActivityType.reported) {
        var query = client
            .from(AppConfig.tableRoadReports)
            .select('id, issue_type, status, created_at, description')
            .eq('user_id', userId)
            .neq('status', 'archived');

        if (categoryFilter != null) {
          query = query.eq('issue_type', categoryFilter.value);
        }
        if (startDate != null) {
          query = query.gte('created_at', startDate.toIso8601String());
        }
        if (endDate != null) {
          query = query.lte('created_at', endDate.toIso8601String());
        }

        final reports = await query.order('created_at', ascending: false).limit(limit + offset);

        for (var r in reports as List) {
          // Fetch first media path for thumbnail
          final media = await client
              .from(AppConfig.tableRoadReportMedia)
              .select('storage_path')
              .eq('report_id', r['id'])
              .order('created_at', ascending: true)
              .limit(1)
              .maybeSingle();

          activities.add(ContributionActivity(
            id: 'rep_${r['id']}',
            reportId: r['id'].toString(),
            activityType: ContributionActivityType.reported,
            category: RoadReportCategory.fromValue(r['issue_type']?.toString() ?? 'other'),
            reportStatus: RoadReportStatus.fromValue(r['status']?.toString() ?? 'pending'),
            createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
            thumbnailPath: media?['storage_path']?.toString(),
            description: r['description']?.toString(),
          ));
        }
      }

      // Fetch user's verifications if filter allows
      if (activityFilter == null || activityFilter == ContributionActivityType.verified) {
        var vQuery = client
            .from(AppConfig.tableRoadReportVerifications)
            .select('id, report_id, verdict, created_at, road_reports!inner(issue_type, status)')
            .eq('user_id', userId);

        if (categoryFilter != null) {
          vQuery = vQuery.eq('road_reports.issue_type', categoryFilter.value);
        }
        if (startDate != null) {
          vQuery = vQuery.gte('created_at', startDate.toIso8601String());
        }
        if (endDate != null) {
          vQuery = vQuery.lte('created_at', endDate.toIso8601String());
        }

        final verifications = await vQuery.order('created_at', ascending: false).limit(limit + offset);

        for (var v in verifications as List) {
          final rep = v['road_reports'] as Map<String, dynamic>?;
          activities.add(ContributionActivity(
            id: 'ver_${v['id']}',
            reportId: v['report_id'].toString(),
            activityType: ContributionActivityType.verified,
            category: RoadReportCategory.fromValue(rep?['issue_type']?.toString() ?? 'other'),
            reportStatus: RoadReportStatus.fromValue(rep?['status']?.toString() ?? 'pending'),
            createdAt: DateTime.tryParse(v['created_at']?.toString() ?? '') ?? DateTime.now(),
            verdict: VerificationVerdict.fromValue(v['verdict']?.toString() ?? 'present'),
          ));
        }
      }

      // Sort combined newest first
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply pagination window
      final end = (offset + limit) > activities.length ? activities.length : (offset + limit);
      if (offset >= activities.length) return [];
      return activities.sublist(offset, end);
    } catch (e, stack) {
      AppLogger.error('Failed to get user contribution activities', e, stack);
      return [];
    }
  }
}

