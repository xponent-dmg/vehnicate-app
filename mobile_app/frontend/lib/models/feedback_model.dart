enum FeedbackCategory {
  bugReport('bug_report', 'Bug Report'),
  featureRequest('feature_request', 'Feature Request'),
  general('general', 'General Feedback');

  final String value;
  final String label;
  const FeedbackCategory(this.value, this.label);

  static FeedbackCategory fromValue(String value) {
    return FeedbackCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FeedbackCategory.general,
    );
  }
}

class FeedbackModel {
  final String? id;
  final String? userId;
  final FeedbackCategory category;
  final String description;
  final List<String> attachmentUrls;
  final String? appVersion;
  final String? buildNumber;
  final String? deviceModel;
  final String? osVersion;
  final String status;
  final String emailStatus;
  final String? emailError;
  final DateTime? createdAt;

  FeedbackModel({
    this.id,
    this.userId,
    required this.category,
    required this.description,
    this.attachmentUrls = const [],
    this.appVersion,
    this.buildNumber,
    this.deviceModel,
    this.osVersion,
    this.status = 'new',
    this.emailStatus = 'pending',
    this.emailError,
    this.createdAt,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'category': category.value,
      'description': description,
      'attachment_urls': attachmentUrls,
      'app_version': appVersion,
      'build_number': buildNumber,
      'device_model': deviceModel,
      'os_version': osVersion,
      'status': status,
      'email_status': emailStatus,
      if (emailError != null) 'email_error': emailError,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      category: FeedbackCategory.fromValue(map['category'] ?? 'general'),
      description: map['description'] ?? '',
      attachmentUrls:
          map['attachment_urls'] != null
              ? List<String>.from(map['attachment_urls'])
              : [],
      appVersion: map['app_version']?.toString(),
      buildNumber: map['build_number']?.toString(),
      deviceModel: map['device_model']?.toString(),
      osVersion: map['os_version']?.toString(),
      status: map['status'] ?? 'new',
      emailStatus: map['email_status'] ?? 'pending',
      emailError: map['email_error']?.toString(),
      createdAt:
          map['created_at'] != null
              ? DateTime.tryParse(map['created_at'])
              : null,
    );
  }
}

