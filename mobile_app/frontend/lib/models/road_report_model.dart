import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

/// 6 required road issue categories
enum RoadReportCategory {
  pothole('pothole', 'Pothole', Icons.warning_amber_rounded),
  markedSpeedbreaker('marked_speedbreaker', 'Marked speedbreaker', Icons.speed_rounded),
  unmarkedSpeedbreaker('unmarked_speedbreaker', 'Unmarked speedbreaker', Icons.report_problem_rounded),
  unpavedRoad('unpaved_road', 'Unpaved road', Icons.terrain_rounded),
  longitudinalCrack('longitudinal_crack', 'Longitudinal crack', Icons.alt_route_rounded),
  other('other', 'Others', Icons.more_horiz_rounded);

  final String value;
  final String label;
  final IconData icon;

  const RoadReportCategory(this.value, this.label, this.icon);

  static RoadReportCategory fromValue(String value) {
    return RoadReportCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RoadReportCategory.other,
    );
  }
}

/// Optional severity levels
enum RoadReportSeverity {
  low('low', 'Low', AppColors.severityLow),
  moderate('moderate', 'Moderate', AppColors.severityMedium),
  high('high', 'High', AppColors.severityCritical);

  final String value;
  final String label;
  final Color color;

  const RoadReportSeverity(this.value, this.label, this.color);

  static RoadReportSeverity? fromValue(String? value) {
    if (value == null) return null;
    return RoadReportSeverity.values.cast<RoadReportSeverity?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// 5 lifecycle statuses for road reports
enum RoadReportStatus {
  pending('pending', 'Pending', AppColors.warning),
  confirmed('confirmed', 'Confirmed', AppColors.severityHigh),
  disputed('disputed', 'Disputed', AppColors.mutedPurple),
  resolved('resolved', 'Resolved', AppColors.success),
  archived('archived', 'Archived', Colors.grey);

  final String value;
  final String label;
  final Color color;

  const RoadReportStatus(this.value, this.label, this.color);

  static RoadReportStatus fromValue(String value) {
    return RoadReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RoadReportStatus.pending,
    );
  }
}

/// Verification responses from users
enum VerificationVerdict {
  present('present', 'Still present', Icons.check_circle_outline_rounded, AppColors.severityHigh),
  repaired('repaired', 'It has been repaired', Icons.build_circle_outlined, AppColors.success),
  incorrect('incorrect', 'Incorrect report', Icons.highlight_off_rounded, AppColors.error);

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const VerificationVerdict(this.value, this.label, this.icon, this.color);

  static VerificationVerdict fromValue(String value) {
    return VerificationVerdict.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VerificationVerdict.present,
    );
  }
}

/// Core Road Report Model
class RoadReport {
  final String id;
  final String userId;
  final RoadReportCategory category;
  final double latitude;
  final double longitude;
  final double? locationAccuracy;
  final RoadReportSeverity? severity;
  final String? description;
  final RoadReportStatus status;
  final String? sourceTripId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceMeters;
  final List<String> mediaStoragePaths;
  final Map<String, int> verificationCounts;
  final VerificationVerdict? userVerdict;
  final bool isOwnReport;

  const RoadReport({
    required this.id,
    required this.userId,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.locationAccuracy,
    this.severity,
    this.description,
    this.status = RoadReportStatus.pending,
    this.sourceTripId,
    required this.createdAt,
    required this.updatedAt,
    this.distanceMeters,
    this.mediaStoragePaths = const [],
    this.verificationCounts = const {'present': 0, 'repaired': 0, 'incorrect': 0},
    this.userVerdict,
    this.isOwnReport = false,
  });

  /// Human-friendly distance formatting (e.g., "75 m" or "1.4 km")
  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }

  /// Relative or standard date formatting
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(createdAt);
    }
  }

  int get totalVerifications {
    return (verificationCounts['present'] ?? 0) +
        (verificationCounts['repaired'] ?? 0) +
        (verificationCounts['incorrect'] ?? 0);
  }

  bool canBeVerifiedBy(String? currentUserId) {
    if (currentUserId == null) return false;
    if (currentUserId == userId) return false;
    if (status == RoadReportStatus.archived) return false;
    return true;
  }

  factory RoadReport.fromRpcMap(Map<String, dynamic> map, {String? currentUserId}) {
    final rawCounts = map['verification_counts'];
    Map<String, int> counts = {'present': 0, 'repaired': 0, 'incorrect': 0};
    if (rawCounts is Map) {
      counts = {
        'present': (rawCounts['present'] as num?)?.toInt() ?? 0,
        'repaired': (rawCounts['repaired'] as num?)?.toInt() ?? 0,
        'incorrect': (rawCounts['incorrect'] as num?)?.toInt() ?? 0,
      };
    }

    final rawMedia = map['media_storage_paths'];
    List<String> media = [];
    if (rawMedia is List) {
      media = rawMedia.map((e) => e.toString()).toList();
    }

    final reportUserId = map['user_id']?.toString() ?? '';
    final isOwn = currentUserId != null
        ? (reportUserId == currentUserId || map['is_own_report'] == true)
        : (map['is_own_report'] == true);

    return RoadReport(
      id: map['id']?.toString() ?? '',
      userId: reportUserId,
      category: RoadReportCategory.fromValue(map['issue_type']?.toString() ?? 'other'),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      locationAccuracy: (map['location_accuracy'] as num?)?.toDouble(),
      severity: RoadReportSeverity.fromValue(map['severity']?.toString()),
      description: map['description']?.toString(),
      status: RoadReportStatus.fromValue(map['status']?.toString() ?? 'pending'),
      sourceTripId: map['source_trip_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      distanceMeters: (map['distance_meters'] as num?)?.toDouble(),
      mediaStoragePaths: media,
      verificationCounts: counts,
      userVerdict: map['user_verdict'] != null
          ? VerificationVerdict.fromValue(map['user_verdict'].toString())
          : null,
      isOwnReport: isOwn,
    );
  }

  factory RoadReport.fromTableMap(
    Map<String, dynamic> map, {
    List<String> mediaPaths = const [],
    Map<String, int> counts = const {'present': 0, 'repaired': 0, 'incorrect': 0},
    VerificationVerdict? userVerdict,
    String? currentUserId,
    double? distanceMeters,
  }) {
    final reportUserId = map['user_id']?.toString() ?? '';
    final isOwn = currentUserId != null && reportUserId == currentUserId;

    return RoadReport(
      id: map['id']?.toString() ?? '',
      userId: reportUserId,
      category: RoadReportCategory.fromValue(map['issue_type']?.toString() ?? 'other'),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      locationAccuracy: (map['location_accuracy'] as num?)?.toDouble(),
      severity: RoadReportSeverity.fromValue(map['severity']?.toString()),
      description: map['description']?.toString(),
      status: RoadReportStatus.fromValue(map['status']?.toString() ?? 'pending'),
      sourceTripId: map['source_trip_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      distanceMeters: distanceMeters,
      mediaStoragePaths: mediaPaths,
      verificationCounts: counts,
      userVerdict: userVerdict,
      isOwnReport: isOwn,
    );
  }

  RoadReport copyWith({
    RoadReportStatus? status,
    Map<String, int>? verificationCounts,
    VerificationVerdict? userVerdict,
    double? distanceMeters,
    List<String>? mediaStoragePaths,
  }) {
    return RoadReport(
      id: id,
      userId: userId,
      category: category,
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: locationAccuracy,
      severity: severity,
      description: description,
      status: status ?? this.status,
      sourceTripId: sourceTripId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      mediaStoragePaths: mediaStoragePaths ?? this.mediaStoragePaths,
      verificationCounts: verificationCounts ?? this.verificationCounts,
      userVerdict: userVerdict ?? this.userVerdict,
      isOwnReport: isOwnReport,
    );
  }
}

/// Verification record model
class RoadReportVerification {
  final String id;
  final String reportId;
  final String userId;
  final VerificationVerdict verdict;
  final String? description;
  final String? evidenceStoragePath;
  final DateTime createdAt;

  const RoadReportVerification({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.verdict,
    this.description,
    this.evidenceStoragePath,
    required this.createdAt,
  });

  factory RoadReportVerification.fromMap(Map<String, dynamic> map) {
    return RoadReportVerification(
      id: map['id']?.toString() ?? '',
      reportId: map['report_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      verdict: VerificationVerdict.fromValue(map['verdict']?.toString() ?? 'present'),
      description: map['description']?.toString(),
      evidenceStoragePath: map['evidence_storage_path']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Activity record for My Contributions screen
enum ContributionActivityType {
  reported('Reported'),
  verified('Verified');

  final String label;
  const ContributionActivityType(this.label);
}

class ContributionActivity {
  final String id;
  final String reportId;
  final ContributionActivityType activityType;
  final RoadReportCategory category;
  final RoadReportStatus reportStatus;
  final DateTime createdAt;
  final String? thumbnailPath;
  final VerificationVerdict? verdict;
  final String? description;

  const ContributionActivity({
    required this.id,
    required this.reportId,
    required this.activityType,
    required this.category,
    required this.reportStatus,
    required this.createdAt,
    this.thumbnailPath,
    this.verdict,
    this.description,
  });

  String get formattedDate {
    return DateFormat('MMM d, yyyy • h:mm a').format(createdAt);
  }
}

/// User stats counts
class UserContributionStats {
  final int reportedCount;
  final int verifiedCount;

  const UserContributionStats({
    required this.reportedCount,
    required this.verifiedCount,
  });
}

