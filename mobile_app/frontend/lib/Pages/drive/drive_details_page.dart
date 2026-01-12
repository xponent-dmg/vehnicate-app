import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/models/drive_model.dart';
import 'package:vehnicate_frontend/Pages/drive/constants/drive_constants.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:vehnicate_frontend/models/event_model.dart';
import 'package:intl/intl.dart';

// Constants and Theme (consistent with other pages)
class DriveDetailsPage extends StatefulWidget {
  final Drive drive;

  const DriveDetailsPage({super.key, required this.drive});

  @override
  State<DriveDetailsPage> createState() => _DriveDetailsPageState();
}

class _DriveDetailsPageState extends State<DriveDetailsPage> {
  final PageController _chartController = PageController();
  int _currentChartIndex = 0;
  bool _isLoading = true;
  List<SensorDataPoint> _sensorData = [];
  List<LatLng> _routePoints = [];
  List<DriveEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchDriveData();
  }

  Future<void> _fetchDriveData() async {
    try {
      final s = SupabaseService();
      final dataFuture = s.fetchDriveData(
        vehicleId: widget.drive.vehicleId,
        startTime: widget.drive.startTime,
        endTime: widget.drive.endTime,
      );
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

      final results = await Future.wait([dataFuture, eventsFuture, routeFuture]);
      final data = results[0];
      final eventsData = results[1];
      final routeData = results[2];

      final points = data.map((e) => SensorDataPoint.fromJson(e)).toList();

      // Route points come pre-filtered (lat/long != 0) with lat, lng columns from Supabase
      final route =
          routeData.map((e) => LatLng((e['latitude'] as num).toDouble(), (e['longitude'] as num).toDouble())).toList();

      final events = eventsData.map((e) => DriveEvent.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _sensorData = points;
          _routePoints = route;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching drive data: $e");
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
    final vehicleName = Provider.of<VehicleProvider>(context).vehicleName ?? 'Vehicle';

    return Scaffold(
      backgroundColor: DriveDetailsConstants.primaryBackground,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
          ),
          child: Column(
            children: [
              _buildHeader(context, vehicleName),
              Expanded(
                child:
                    _isLoading
                        ? Center(child: CircularProgressIndicator(color: DriveDetailsConstants.accentPurple))
                        : SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              _buildMapSection(),
                              SizedBox(height: 24),
                              _buildChartsSection(),
                              SizedBox(height: 24),
                              _buildMetricsGrid(),
                            ],
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String vehicleName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding, vertical: 16),
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
                Text(_formatDate(widget.drive.startTime), style: DriveDetailsConstants.subtitleStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    if (_routePoints.isEmpty) {
      return Container(
        height: 200,
        margin: EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding),
        decoration: BoxDecoration(
          color: DriveDetailsConstants.cardBackground,
          borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
        ),
        child: Center(child: Text("No GPS data available for this trip", style: DriveDetailsConstants.subtitleStyle)),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DriveDetailsConstants.cardBackground,
        borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
        border: Border.all(color: DriveDetailsConstants.accentPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Route Preview", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _showRouteDebugLogs, icon: Icon(Icons.bug_report, color: Colors.white54, size: 20)),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
              child: _routePreviewWidget(_routePoints),
            ),
          ),
          SizedBox(height: 12),
          Text("Event Legend", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 8),
          _buildMapLegend(),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    if (_sensorData.isEmpty) return SizedBox.shrink();

    return Column(
      children: [
        // Chart indicators
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentChartIndex == index ? DriveDetailsConstants.accentPurple : Colors.white30,
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 16),

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
              _buildChartCard(title: 'Acceleration (m/s²)', chart: _buildSensorChart(isAccel: true)),
              _buildChartCard(title: 'Gyroscope (rad/s)', chart: _buildSensorChart(isAccel: false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: DriveDetailsConstants.cardBackground,
          borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
          boxShadow: [
            BoxShadow(color: DriveDetailsConstants.lightPurple.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
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
    if (_sensorData.length > 200) {
      final step = _sensorData.length ~/ 100;
      displayData = [];
      for (int i = 0; i < _sensorData.length; i += step) {
        displayData.add(_sensorData[i]);
      }
    }

    if (displayData.isEmpty) return Center(child: Text("No data"));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations:
              _events.map((e) {
                final startDiff = e.timestamp.difference(widget.drive.startTime).inSeconds.toDouble();
                final endDiff = e.endTimestamp.difference(widget.drive.startTime).inSeconds.toDouble();
                return VerticalRangeAnnotation(
                  x1: startDiff,
                  x2: endDiff,
                  color: _getEventColor(e.type).withOpacity(0.2),
                );
              }).toList(),
        ),
        lineBarsData: [
          _buildLine(displayData, (p) => isAccel ? p.accelX : p.gyroX, Colors.red),
          _buildLine(displayData, (p) => isAccel ? p.accelY : p.gyroY, Colors.green),
          _buildLine(displayData, (p) => isAccel ? p.accelZ : p.gyroZ, Colors.blue),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<SensorDataPoint> data, double Function(SensorDataPoint) selector, Color color) {
    return LineChartBarData(
      spots:
          data.map((d) {
            // Use relative time in seconds from start
            final diff = d.timeSent.difference(widget.drive.startTime).inSeconds.toDouble();
            return FlSpot(diff, selector(d));
          }).toList(),
      isCurved: false, // Fixed: removed curves to reduce messiness
      color: color,
      barWidth: 2,
      dotData: FlDotData(show: false),
    );
  }

  Widget _buildMetricsGrid() {
    final duration = widget.drive.endTime.difference(widget.drive.startTime);
    final avgSpeed =
        duration.inHours > 0
            ? widget.drive.distance / duration.inHours
            : (duration.inMinutes > 0 ? widget.drive.distance / (duration.inMinutes / 60) : 0.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding),
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

  Widget _buildMetricItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DriveDetailsConstants.darkPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DriveDetailsConstants.accentPurple, size: 16),
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
      options: MapOptions(
        // Use standard center for single point, CameraFit for paths
        initialCenter: uniquePath.length == 1 ? uniquePath.first : const LatLng(0, 0),
        initialZoom: uniquePath.length == 1 ? 15.0 : 13.0,
        initialCameraFit:
            uniquePath.length > 1
                ? CameraFit.bounds(bounds: LatLngBounds.fromPoints(uniquePath), padding: const EdgeInsets.all(50.0))
                : null,
      ),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
        PolylineLayer(polylines: [Polyline(points: uniquePath, strokeWidth: 4.0, color: Colors.blue)]),
        MarkerLayer(
          markers: [
            Marker(point: uniquePath.first, child: const Icon(Icons.circle, color: Colors.green, size: 15)),
            Marker(point: uniquePath.last, child: const Icon(Icons.stop_circle, color: Colors.red, size: 20)),
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
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
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
                Icon(Icons.warning_amber_rounded, color: _getEventColor(event.type)),
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
                Text('Source: ${event.source}', style: DriveDetailsConstants.metricLabelStyle),
                Text('Severity: ${event.severity}', style: DriveDetailsConstants.metricLabelStyle),
                Text('Confidence: ${(event.confidence * 100).toInt()}%', style: DriveDetailsConstants.metricLabelStyle),
                Text(
                  'Time: ${DateFormat('HH:mm:ss').format(event.timestamp.toLocal())}',
                  style: DriveDetailsConstants.metricLabelStyle,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: DriveDetailsConstants.accentPurple)),
              ),
            ],
          ),
    );
  }

  Widget _buildMapLegend() {
    // Collect unique event types present in data
    final presentTypes = _events.map((e) => e.type).toSet().toList();

    // Always include Start/End
    final List<MapEntry<String, Color>> legendItems = [MapEntry('Start', Colors.green), MapEntry('End', Colors.red)];

    // Add event types
    for (var type in presentTypes) {
      legendItems.add(MapEntry(type.replaceAll('_', ' ').toUpperCase(), _getEventColor(type)));
    }

    if (presentTypes.isEmpty && legendItems.length == 2) {
      return Text("No events detected in this drive.", style: TextStyle(color: Colors.white54, fontSize: 12));
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          legendItems.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                SizedBox(width: 6),
                Text(e.key, style: TextStyle(color: Colors.white70, fontSize: 12)),
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
            title: Text("Route Data (${_routePoints.length} points)", style: DriveDetailsConstants.titleStyle),
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
                          style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
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
                child: Text("Close", style: TextStyle(color: DriveDetailsConstants.accentPurple)),
              ),
            ],
          ),
    );
  }
}
