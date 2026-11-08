import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/road_report_provider.dart';
import 'package:vehnway/config/config.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/models/road_report_model.dart';
import 'package:vehnway/services/page_transitions.dart';
import 'package:vehnway/services/supabase/road_report_service.dart';
import 'package:vehnway/Pages/reports/create_report_page.dart';
import 'package:vehnway/Pages/reports/my_contributions_page.dart';
import 'package:vehnway/Pages/reports/report_details_page.dart';
import 'package:vehnway/Pages/reports/widgets/report_card.dart';

class ReportsMapPage extends StatefulWidget {
  const ReportsMapPage({super.key});

  @override
  State<ReportsMapPage> createState() => ReportsMapPageState();
}

class ReportsMapPageState extends State<ReportsMapPage> {
  late final MapController _mapController;
  Timer? _debounceTimer;
  String? _previewThumbnailUrl;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onReportTapped(RoadReport report) async {
    final provider = context.read<RoadReportProvider>();
    provider.selectReport(report);

    _mapController.move(LatLng(report.latitude, report.longitude), 16.5);

    if (report.mediaStoragePaths.isNotEmpty) {
      final url = await RoadReportService().getSignedImageUrl(
        report.mediaStoragePaths.first,
      );
      if (mounted) setState(() => _previewThumbnailUrl = url);
    } else {
      if (mounted) setState(() => _previewThumbnailUrl = null);
    }
  }

  void _openReportDetails(RoadReport report) {
    Navigator.push(
      context,
      PageTransitions.fadeSlideUp(ReportDetailsPage(report: report)),
    );
  }

  void openCreateReport() {
    Navigator.push(
      context,
      PageTransitions.fadeSlideUp(const CreateReportPage()),
    );
  }

  void _openMyContributions() {
    Navigator.push(
      context,
      PageTransitions.fadeSlideUp(const MyContributionsPage()),
    );
  }

  void _reCenterToUserLocation() {
    final provider = context.read<RoadReportProvider>();
    _mapController.move(provider.currentLocation, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoadReportProvider>();
    final nearbyReports = provider.nearbyReports;
    final selectedReport = provider.selectedReport;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 1. Contained Interactive Map Card (fixed space)
          _buildContainedMapCard(provider, nearbyReports),

          // 2. Optional compact preview if a marker was selected
          if (selectedReport != null)
            _buildSelectedReportPreview(selectedReport, provider),

          // 3. Section Header: Reports Nearby with Contributions button
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Reports Nearby (${nearbyReports.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _openMyContributions,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      'Contributions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          // 4. Dropdown filter chips right under Reports Nearby heading
          _buildFilterChipsRow(provider),
          const SizedBox(height: 6),

          // 5. Scrollable Nearby Reports List or Empty State
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => provider.loadNearbyReports(),
              child:
                  nearbyReports.isEmpty && !provider.isLoading
                      ? _buildEmptyState()
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: nearbyReports.length,
                        itemBuilder: (context, index) {
                          final report = nearbyReports[index];
                          return ReportCard(
                            report: report,
                            onTap: () => _openReportDetails(report),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(RoadReportProvider provider) {
    final hasActiveFilter =
        provider.selectedCategoryFilter != null ||
        provider.selectedStatusFilter != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Category dropdown chip
          PopupMenuButton<RoadReportCategory?>(
            initialValue: provider.selectedCategoryFilter,
            color: AppColors.surface,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white12),
            ),
            tooltip: 'Filter by Category',
            onSelected: (cat) => provider.setCategoryFilter(cat),
            itemBuilder:
                (context) => [
                  const PopupMenuItem<RoadReportCategory?>(
                    value: null,
                    child: Text(
                      'All Categories',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  ...RoadReportCategory.values.map(
                    (c) => PopupMenuItem<RoadReportCategory?>(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            c.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    provider.selectedCategoryFilter != null
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      provider.selectedCategoryFilter != null
                          ? AppColors.primary
                          : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.selectedCategoryFilter == null
                        ? 'Category: All'
                        : provider.selectedCategoryFilter!.label,
                    style: TextStyle(
                      color:
                          provider.selectedCategoryFilter != null
                              ? Colors.white
                              : Colors.white70,
                      fontSize: 11,
                      fontWeight:
                          provider.selectedCategoryFilter != null
                              ? FontWeight.bold
                              : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Status dropdown chip
          PopupMenuButton<RoadReportStatus?>(
            initialValue: provider.selectedStatusFilter,
            color: AppColors.surface,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white12),
            ),
            tooltip: 'Filter by Status',
            onSelected: (st) => provider.setStatusFilter(st),
            itemBuilder:
                (context) => [
                  const PopupMenuItem<RoadReportStatus?>(
                    value: null,
                    child: Text(
                      'All Statuses',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  ...[
                    RoadReportStatus.pending,
                    RoadReportStatus.confirmed,
                    RoadReportStatus.resolved,
                    RoadReportStatus.disputed,
                  ].map(
                    (s) => PopupMenuItem<RoadReportStatus?>(
                      value: s,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    provider.selectedStatusFilter != null
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      provider.selectedStatusFilter != null
                          ? AppColors.primary
                          : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.selectedStatusFilter == null
                        ? 'Status: All'
                        : provider.selectedStatusFilter!.label,
                    style: TextStyle(
                      color:
                          provider.selectedStatusFilter != null
                              ? Colors.white
                              : Colors.white70,
                      fontSize: 11,
                      fontWeight:
                          provider.selectedStatusFilter != null
                              ? FontWeight.bold
                              : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          if (hasActiveFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                provider.setCategoryFilter(null);
                provider.setStatusFilter(null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 12, color: Colors.white70),
                    SizedBox(width: 3),
                    Text(
                      'Clear',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContainedMapCard(
    RoadReportProvider provider,
    List<RoadReport> reports,
  ) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkGreyBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: provider.currentLocation,
                initialZoom: 15.0,
                minZoom: 3.0,
                maxZoom: 19.0,
                onTap: (_, __) {
                  if (provider.selectedReport != null) {
                    provider.selectReport(null);
                  }
                },
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) {
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 600),
                      () {
                        provider.updateLocation(camera.center);
                        provider.loadNearbyReports(showLoading: false);
                      },
                    );
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: Config.cartoVoyagerUrl,
                  userAgentPackageName: 'com.vehnicate.app',
                ),

                MarkerLayer(
                  markers: [
                    // User current location marker
                    Marker(
                      point: provider.currentLocation,
                      width: 38,
                      height: 38,
                      child: _buildUserLocationMarker(),
                    ),

                    // Road report markers
                    ...reports.map((report) {
                      final isSelected =
                          provider.selectedReport?.id == report.id;
                      return Marker(
                        point: LatLng(report.latitude, report.longitude),
                        width: isSelected ? 44 : 34,
                        height: isSelected ? 44 : 34,
                        child: GestureDetector(
                          onTap: () => _onReportTapped(report),
                          child: _buildReportMarker(report, isSelected),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            // Re-center button
            Positioned(
              right: 10,
              bottom: 10,
              child: GestureDetector(
                onTap: _reCenterToUserLocation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreyBackground.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportMarker(RoadReport report, bool isSelected) {
    final statusColor = report.status.color;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isSelected ? 1.15 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white70,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.5),
              blurRadius: isSelected ? 8 : 4,
            ),
          ],
        ),
        child: Icon(
          report.category.icon,
          size: isSelected ? 18 : 15,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSelectedReportPreview(
    RoadReport report,
    RoadReportProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkGreyBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: report.status.color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.surface,
              child:
                  _previewThumbnailUrl != null
                      ? Image.network(_previewThumbnailUrl!, fit: BoxFit.cover)
                      : Icon(
                        report.category.icon,
                        color: AppColors.primary,
                        size: 24,
                      ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _openReportDetails(report),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.category.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        report.formattedDistance,
                        style: const TextStyle(
                          color: AppColors.lightPurple,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap to view details & verify →',
                    style: TextStyle(color: AppColors.primary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.white54),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => provider.selectReport(null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'No reports nearby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'No road issues have been reported in this area.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
