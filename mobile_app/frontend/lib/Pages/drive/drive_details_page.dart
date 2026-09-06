import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/models/drive_model.dart';
import 'package:vehnway/Pages/drive/constants/drive_constants.dart';
import 'package:vehnway/services/supabase/supabase_drive_service.dart';
import 'package:vehnway/models/event_model.dart';
import 'package:intl/intl.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/config/config.dart';

// Constants and Theme (consistent with other pages)
class DriveDetailsPage extends StatefulWidget {
  final Drive drive;

  const DriveDetailsPage({super.key, required this.drive});

  @override
  State<DriveDetailsPage> createState() => _DriveDetailsPageState();
}

class _DriveDetailsPageState extends State<DriveDetailsPage>
    with TickerProviderStateMixin {
  final PageController _chartController = PageController();
  // int _currentChartIndex = 0;
  bool _isLoading = true;
  // List<SensorDataPoint> _sensorData = [];
  List<LatLng> _routePoints = [];
  List<DriveEvent> _events = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchDriveData();
  }

  Future<void> _fetchDriveData() async {
    try {
      final s = SupabaseDriveService();
      // final dataFuture = s.fetchDriveData(
      //   vehicleId: widget.drive.vehicleId,
      //   startTime: widget.drive.startTime,
      //   endTime: widget.drive.endTime,
      // );
      final eventsFuture = s.fetchDriveEvents(
        vehicleId: widget.drive.vehicleId,
        startTime: widget.drive.startTime,
        endTime: widget.drive.endTime,
      );
      final routeFuture = s.fetchDriveRoute(
        vehicleId: widget.drive.vehicleId,
        startTime: widget.drive.startTime,
        endTime: widget.drive.endTime,
      );

      final results = await Future.wait([
        // dataFuture,
        eventsFuture,
        routeFuture,
      ]);
      // final data = results[0];
      final eventsData = results[0];
      final routeData = results[1];

      // final points = data.map((e) => SensorDataPoint.fromJson(e)).toList();

      // Route points come pre-filtered (lat/long != 0) with lat, lng columns from Supabase
      final route =
          routeData
              .map(
                (e) => LatLng(
                  (e['latitude'] as num).toDouble(),
                  (e['longitude'] as num).toDouble(),
                ),
              )
              .toList();

      final events = eventsData.map((e) => DriveEvent.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          // _sensorData = points;
          _routePoints = route;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleName =
        Provider.of<VehicleProvider>(context).vehicleModel ?? 'Vehicle';

    return Scaffold(
      backgroundColor: const Color(
        0xFF0F1115,
      ), // Dark premium background matching VehicleDetails
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          vehicleName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25.0, top: 10.0, bottom: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat(
                    'dd MMM yyyy',
                  ).format(widget.drive.startTime.toLocal()),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm').format(widget.drive.startTime.toLocal()),
                  style: const TextStyle(
                    color: AppColors.buttonBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.buttonBlue),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    _buildMapSection(),
                    const SizedBox(height: 30),
                    _buildMetricsGrid(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
    );
  }

  Widget _buildMapSection() {
    if (_routePoints.isEmpty) {
      return GlassLiteContainer(
        height: 200,
        backgroundColor: AppColors.darkGreyBackground,
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Text(
            "No GPS data available for this trip",
            style: DriveDetailsConstants.subtitleStyle,
          ),
        ),
      );
    }

    return GlassLiteContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(20),
      backgroundColor: AppColors.darkGreyBackground,
      hasBorder: true,
      borderColor: Colors.white.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Route Preview",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onLongPress: _showRouteDebugLogs,
                onPressed: () {
                  if (_routePoints.isEmpty) return;

                  LatLng targetCenter;
                  double targetZoom;

                  if (_routePoints.length > 1) {
                    final bounds = LatLngBounds.fromPoints(_routePoints);
                    // constraints used to calculate center/zoom
                    final fitted = CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(50.0),
                    ).fit(_mapController.camera);
                    targetCenter = fitted.center;
                    targetZoom = fitted.zoom;
                  } else {
                    targetCenter = _routePoints.first;
                    targetZoom = 15.0;
                  }

                  _animatedMapMove(targetCenter, targetZoom, 0.0);
                },
                icon: const Icon(
                  Icons.fit_screen_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _routePreviewWidget(_routePoints),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Event Legend",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildMapLegend(),
        ],
      ),
    );
  }

  /*
  Widget _buildChartsSection() {
    if (_sensorData.isEmpty) return SizedBox.shrink();

    return Column(
      children: [
        // Swipeable charts
        SizedBox(
          height: 300,
          child: PageView(
            controller: _chartController,
            onPageChanged: (index) {
              setState(() {
                _currentChartIndex = index;
              });
            },
            children: [
              _buildChartCard(
                title: 'Acceleration (m/s²)',
                chart: _buildSensorChart(isAccel: true),
              ),
              _buildChartCard(
                title: 'Gyroscope (rad/s)',
                chart: _buildSensorChart(isAccel: false),
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // Chart indicators
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DriveDetailsConstants.horizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentChartIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.white30,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }


  Widget _buildChartCard({required String title, required Widget chart}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DriveDetailsConstants.horizontalPadding,
      ),
      child: GlassLiteContainer(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
        hasShadow: true,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DriveDetailsConstants.cardTitleStyle),
              SizedBox(height: 16),
              Expanded(child: chart),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildSensorChart({required bool isAccel}) {
    // Downsample if too many points to avoid lag
    // Downsample if too many points to avoid lag
    List<SensorDataPoint> displayData = _sensorData;
    // Increase the threshold - 100 is too low for sensors
    if (_sensorData.length > 1000) {
      final step = _sensorData.length ~/ 500;
      displayData = [];
      for (int i = 0; i < _sensorData.length; i += step) {
        displayData.add(_sensorData[i]);
      }
    }

    if (displayData.isEmpty) return Center(child: Text("No data"));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          // drawHorizontalLine: false,
          horizontalInterval: 5,
        ),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations:
              _events.map((e) {
                final startDiff =
                    e.timestamp
                        .difference(widget.drive.startTime)
                        .inSeconds
                        .toDouble();
                final endDiff =
                    e.endTimestamp
                        .difference(widget.drive.startTime)
                        .inSeconds
                        .toDouble();
                return VerticalRangeAnnotation(
                  x1: startDiff,
                  x2: endDiff,
                  color: _getEventColor(e.type).withOpacity(0.2),
                );
              }).toList(),
        ),
        lineBarsData: [
          _buildLine(
            displayData,
            (p) => isAccel ? p.accelX : p.gyroX,
            Colors.red,
          ),
          _buildLine(
            displayData,
            (p) => isAccel ? p.accelY : p.gyroY,
            Colors.green,
          ),
          _buildLine(
            displayData,
            (p) => isAccel ? p.accelZ : p.gyroZ,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(
    List<SensorDataPoint> data,
    double Function(SensorDataPoint) selector,
    Color color,
  ) {
    return LineChartBarData(
      spots:
          data.map((d) {
            // Use relative time in seconds from start
            final diff =
                d.timeSent
                    .difference(widget.drive.startTime)
                    .inSeconds
                    .toDouble();
            return FlSpot(diff, selector(d));
          }).toList(),
      isCurved: false, // Fixed: removed curves to reduce messiness
      color: color,
      barWidth: 1.2,
      dotData: FlDotData(show: false),
    );
  }

  */

  Widget _buildMetricsGrid() {
    final duration = widget.drive.endTime.difference(widget.drive.startTime);
    final avgSpeed =
        duration.inHours > 0
            ? widget.drive.distance / duration.inHours
            : (duration.inMinutes > 0
                ? widget.drive.distance / (duration.inMinutes / 60)
                : 0.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                icon: FontAwesomeIcons.clock,
                label: 'Duration',
                value: _formatDuration(duration),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricItem(
                icon: FontAwesomeIcons.road,
                label: 'Distance',
                value: '${widget.drive.distance.toStringAsFixed(1)} km',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                icon: FontAwesomeIcons.tachometerAlt,
                label: 'Avg Speed',
                value: '${avgSpeed.toStringAsFixed(1)} km/h',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GlassLiteContainer(
      height: 100,
      backgroundColor: AppColors.darkGreyBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[400], size: 18),
                const SizedBox(width: 8),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // String _formatDate(DateTime date) {
  //   return DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
  // }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Widget _routePreviewWidget(List<LatLng> fullPath) {
    // Remove consecutive duplicates to preserve path relationships while cleaning noise
    List<LatLng> uniquePath = [];
    if (fullPath.isNotEmpty) {
      uniquePath.add(fullPath.first);
      for (int i = 1; i < fullPath.length; i++) {
        // Simple equality check for consecutive points
        if (fullPath[i] != fullPath[i - 1]) {
          uniquePath.add(fullPath[i]);
        }
      }
    }

    if (uniquePath.isEmpty) return SizedBox();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        // Use standard center for single point, CameraFit for paths
        initialCenter:
            uniquePath.length == 1 ? uniquePath.first : const LatLng(0, 0),
        initialZoom: uniquePath.length == 1 ? 15.0 : 13.0,
        initialCameraFit:
            uniquePath.length > 1
                ? CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(uniquePath),
                  padding: const EdgeInsets.all(50.0),
                )
                : null,
      ),
      children: [
        TileLayer(
          urlTemplate: Config.cartoVoyagerUrl,
          userAgentPackageName: 'com.vehnicate.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: uniquePath,
              strokeWidth: 4.0,
              color: AppColors.buttonBlue,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: uniquePath.first,
              child: const Icon(Icons.circle, color: Colors.green, size: 15),
            ),
            Marker(
              point: uniquePath.last,
              child: const Icon(
                Icons.circle_sharp,
                color: Colors.orange,
                size: 17,
              ),
            ),
            // Event Markers
            ..._events.map(
              (e) => Marker(
                point: LatLng(e.latitude, e.longitude),
                height: 20,
                width: 20,
                child: GestureDetector(
                  onTap: () => _showEventDetails(e),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getEventColor(e.type),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return AppColors.severityCritical;
      case 'road_defect':
        return AppColors.severityHigh;
      case 'unmarked_speedbump':
        return AppColors.severityMedium;
      case 'marked_speedbump':
        return AppColors.severityLow;
      case 'cracks':
        return AppColors.severityInfo;
      case 'unpaved_road':
        return AppColors.severitySuccess;
      case 'harsh_braking':
        return Color(0xFFFCD34D);
      case 'harsh_acceleration':
        return Color(0xFFFDE047);
      case 'sharp_turn':
        return Color(0xFFFEF08A);
      case 'swerving':
        return Color(0xFFFBBF24);
      default:
        return Color(0xFFFBBF24);
    }
  }

  void _showEventDetails(DriveEvent event) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: DriveDetailsConstants.cardBackground,
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: _getEventColor(event.type),
                ),
                SizedBox(width: 8),
                Text(
                  event.type.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source: ${event.source}',
                  style: DriveDetailsConstants.metricLabelStyle,
                ),
                Text(
                  'Severity: ${event.severity}',
                  style: DriveDetailsConstants.metricLabelStyle,
                ),
                Text(
                  'Confidence: ${(event.confidence * 100).toInt()}%',
                  style: DriveDetailsConstants.metricLabelStyle,
                ),
                Text(
                  'Time: ${DateFormat('HH:mm:ss').format(event.timestamp.toLocal())}',
                  style: DriveDetailsConstants.metricLabelStyle,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: AppColors.buttonBlue),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMapLegend() {
    // Collect unique event types present in data
    final presentTypes = _events.map((e) => e.type).toSet().toList();

    // Always include Start/End
    final List<MapEntry<String, Color>> legendItems = [
      MapEntry('Start', Colors.green),
      MapEntry('End', Colors.red),
    ];

    // Add event types
    for (var type in presentTypes) {
      legendItems.add(
        MapEntry(type.replaceAll('_', ' ').toUpperCase(), _getEventColor(type)),
      );
    }

    if (presentTypes.isEmpty && legendItems.length == 2) {
      return Text(
        "No events detected in this drive.",
        style: TextStyle(color: Colors.white54, fontSize: 12),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          legendItems.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: e.value,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  e.key,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            );
          }).toList(),
    );
  }

  void _showRouteDebugLogs() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: DriveDetailsConstants.cardBackground,
            title: Text(
              "Route Data (${_routePoints.length} points)",
              style: DriveDetailsConstants.titleStyle,
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _routePoints.length,
                itemBuilder: (context, index) {
                  final p = _routePoints[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Text(
                          "${index + 1}. ",
                          style: const TextStyle(
                            color: AppColors.buttonBlue,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "[${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}]",
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: AppColors.buttonBlue),
                ),
              ),
            ],
          ),
    );
  }

  void _animatedMapMove(
    LatLng destLocation,
    double destZoom,
    double destRotation,
  ) {
    // Create some variables to hold the current state
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );
    final rotateTween = Tween<double>(
      begin: _mapController.camera.rotation,
      end: destRotation,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
      _mapController.rotate(rotateTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
}
