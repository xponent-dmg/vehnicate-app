class AppConfig {
  // Supabase Table Names
  static const String tableUserDetails = 'user_details';
  static const String tableVehicleDetails = 'vehicle_details';
  static const String tableSessions = 'sessions';
  static const String tableDrivingEvents = 'driving_events';
  static const String tableImuData = 'imu_data';
  static const String tableGpsData = 'gps_data';
  static const String tableFrames = 'frames';
  static const String tableAppFeedback = 'app_feedback';
  static const String tableRoadReports = 'road_reports';
  static const String tableRoadReportMedia = 'road_report_media';
  static const String tableRoadReportVerifications = 'road_report_verifications';

  // Supabase Storage Buckets
  static const String bucketUserAvatars = 'user_avatars';
  static const String bucketVehicleImages = 'vehicle_ride_img';
  static const String bucketFeedbackAttachments = 'feedback-attachments';
  static const String bucketRoadReportMedia = 'road-report-media';
}
