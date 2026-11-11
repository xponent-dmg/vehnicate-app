import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:vehnway/config/config.dart';
import 'package:vehnway/models/road_report_model.dart';
import 'package:vehnway/services/map_service.dart';
import 'package:vehnway/services/supabase/road_report_service.dart';
import 'package:vehnway/utils/app_logger.dart';

class RoadReportProvider extends ChangeNotifier {
  final _service = RoadReportService();
  final _mapService = const MapService();

  LatLng _currentLocation = LatLng(Config.defaultLatitude, Config.defaultLongitude);
  double? _locationAccuracy;
  bool _isLocationInitialized = false;

  double _searchRadiusMeters = 2000.0;
  RoadReportCategory? _selectedCategoryFilter;
  RoadReportStatus? _selectedStatusFilter;

  List<RoadReport> _nearbyReports = [];
  RoadReport? _selectedReport;
  bool _isLoading = false;
  String? _errorMessage;

  // Contribution state
  UserContributionStats _contributionStats = const UserContributionStats(reportedCount: 0, verifiedCount: 0);
  bool _isLoadingStats = false;

  // Getters
  LatLng get currentLocation => _currentLocation;
  double? get locationAccuracy => _locationAccuracy;
  bool get isLocationInitialized => _isLocationInitialized;
  double get searchRadiusMeters => _searchRadiusMeters;
  RoadReportCategory? get selectedCategoryFilter => _selectedCategoryFilter;
  RoadReportStatus? get selectedStatusFilter => _selectedStatusFilter;
  List<RoadReport> get nearbyReports => _nearbyReports;
  RoadReport? get selectedReport => _selectedReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserContributionStats get contributionStats => _contributionStats;
  bool get isLoadingStats => _isLoadingStats;

  RoadReportProvider() {
    initializeLocation();
  }

  /// Obtains current GPS position and loads nearby reports
  Future<void> initializeLocation() async {
    try {
      final position = await _mapService.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationAccuracy = position.accuracy;
      _isLocationInitialized = true;
      notifyListeners();

      await loadNearbyReports();
    } catch (e, stack) {
      AppLogger.warning('Could not acquire device GPS for road reports', e, stack);
      // Fallback to default coordinates and load
      _isLocationInitialized = true;
      notifyListeners();
      await loadNearbyReports();
    }
  }

  /// Sets current coordinates directly (e.g. on manual movement or GPS updates)
  void updateLocation(LatLng newLocation, {double? accuracy}) {
    _currentLocation = newLocation;
    if (accuracy != null) _locationAccuracy = accuracy;
    notifyListeners();
  }

  /// Loads reports within active radius and filters
  Future<void> loadNearbyReports({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final reports = await _service.getNearbyReports(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        radiusMeters: _searchRadiusMeters,
        categoryFilter: _selectedCategoryFilter?.value,
        statusFilter: _selectedStatusFilter?.value,
      );

      _nearbyReports = reports;
      _errorMessage = null;

      // Update selected report reference if it is in the new list
      if (_selectedReport != null) {
        final updated = reports.cast<RoadReport?>().firstWhere(
          (r) => r?.id == _selectedReport!.id,
          orElse: () => null,
        );
        if (updated != null) {
          _selectedReport = updated;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load road reports: $e';
      AppLogger.error('RoadReportProvider.loadNearbyReports error', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the category filter and refreshes data
  void setCategoryFilter(RoadReportCategory? category) {
    if (_selectedCategoryFilter == category) return;
    _selectedCategoryFilter = category;
    notifyListeners();
    loadNearbyReports();
  }

  /// Changes the status filter and refreshes data
  void setStatusFilter(RoadReportStatus? status) {
    if (_selectedStatusFilter == status) return;
    _selectedStatusFilter = status;
    notifyListeners();
    loadNearbyReports();
  }

  /// Clears all active filters
  void clearFilters() {
    _selectedCategoryFilter = null;
    _selectedStatusFilter = null;
    notifyListeners();
    loadNearbyReports();
  }

  /// Sets search radius (in meters)
  void setSearchRadius(double radiusMeters) {
    if (_searchRadiusMeters == radiusMeters) return;
    _searchRadiusMeters = radiusMeters;
    notifyListeners();
    loadNearbyReports();
  }

  /// Selects or deselects a report for preview
  void selectReport(RoadReport? report) {
    _selectedReport = report;
    notifyListeners();
  }

  /// Appends or updates a newly submitted report in the list
  void onReportCreated(RoadReport newReport) {
    _nearbyReports.insert(0, newReport);
    _selectedReport = newReport;
    notifyListeners();
    loadContributionStats();
  }

  /// Refreshes report and verifications after user verification
  Future<void> onVerificationSubmitted(String reportId) async {
    final updated = await _service.getReportById(
      reportId,
      userLat: _currentLocation.latitude,
      userLon: _currentLocation.longitude,
    );

    if (updated != null) {
      final index = _nearbyReports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _nearbyReports[index] = updated;
      }
      if (_selectedReport?.id == reportId) {
        _selectedReport = updated;
      }
      notifyListeners();
    }

    loadContributionStats();
  }

  /// Loads contribution counts for statistics cards
  Future<void> loadContributionStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      _contributionStats = await _service.getUserContributionStats();
    } catch (e) {
      AppLogger.warning('Failed to load contribution stats', e);
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }
}

