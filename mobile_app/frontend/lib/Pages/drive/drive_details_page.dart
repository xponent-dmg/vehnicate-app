import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:opsin/Providers/vehicle_provider.dart';
import 'package:opsin/models/drive_model.dart';
import 'package:opsin/Pages/drive/constants/drive_constants.dart';
import 'package:opsin/services/supabase_service.dart';
import 'package:opsin/models/event_model.dart';
import 'package:intl/intl.dart';
import 'package:opsin/Widgets/glass_lite_container.dart';

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
      final s = SupabaseService();
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
      backgroundColor: DriveDetailsConstants.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, vehicleName),
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                      : SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            _buildMapSection(),
                            SizedBox(height: 40),
                            // _buildChartsSection(),
                            // SizedBox(height: 40),
                            _buildMetricsGrid(),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String vehicleName) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DriveDetailsConstants.horizontalPadding,
        vertical: 16,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicleName, style: DriveDetailsConstants.titleStyle),
                Text(
                  _formatDate(widget.drive.startTime),
                  style: DriveDetailsConstants.subtitleStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    if (_routePoints.isEmpty) {
      return GlassLiteContainer(
        height: 200,
        margin: EdgeInsets.symmetric(
          horizontal: DriveDetailsConstants.horizontalPadding,
        ),
        borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
        child: Center(
          child: Text(
            "No GPS data available for this trip",
            style: DriveDetailsConstants.subtitleStyle,
          ),
        ),
      );
    }

    return GlassLiteContainer(
      margin: EdgeInsets.symmetric(
        horizontal: DriveDetailsConstants.horizontalPadding,
      ),
      padding: EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
      borderColor: Theme.of(context).primaryColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Route Preview",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                icon: Icon(
                  Icons.fit_screen_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                DriveDetailsConstants.cardRadius,
              ),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                DriveDetailsConstants.cardRadius,
              ),
              child: _routePreviewWidget(_routePoints),
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Event Legend",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DriveDetailsConstants.horizontalPadding,
      ),
      child: Column(
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
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  icon: FontAwesomeIcons.road,
                  label: 'Distance',
                  value: '${widget.drive.distance.toStringAsFixed(1)} km',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GlassLiteContainer(
      padding: EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 16),
              SizedBox(width: 6),
              Text(label, style: DriveDetailsConstants.metricLabelStyle),
            ],
          ),
          SizedBox(height: 4),
          Text(value, style: DriveDetailsConstants.metricValueStyle),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
  }

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
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.vehnicate.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: uniquePath,
              strokeWidth: 4.0,
              color: Theme.of(context).primaryColor,
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
        return Color(0xFFEF4444);
      case 'road_defect':
        return Color(0xFFDC2626);
      case 'unmarked_speedbump':
        return Color(0xFFF59E0B);
      case 'marked_speedbump':
        return Color(0xFF8B5CF6);
      case 'cracks':
        return Color(0xFF06B6D4);
      case 'unpaved_road':
        return Color(0xFF10B981);
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
                child: Text(
                  'Close',
                  style: TextStyle(color: DriveDetailsConstants.accentPurple),
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
            content: Container(
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
                          style: TextStyle(
                            color: DriveDetailsConstants.accentPurple,
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
                child: Text(
                  "Close",
                  style: TextStyle(color: DriveDetailsConstants.accentPurple),
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
