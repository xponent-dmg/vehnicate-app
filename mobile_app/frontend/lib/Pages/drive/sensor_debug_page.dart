import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Pages/profile/constants/profile_constants.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/Widgets/custom_snackbar.dart';
import 'package:vehnicate_frontend/models/sensor_data.dart';
import 'package:vehnicate_frontend/services/location_permission_service.dart';

import 'package:vehnicate_frontend/services/sensor_service.dart';

/// Debug page for visualizing sensor data and coordinate conversion
class SensorDebugPage extends StatefulWidget {
  const SensorDebugPage({super.key});

  @override
  State<SensorDebugPage> createState() => _SensorDebugPageState();
}

class _SensorDebugPageState extends State<SensorDebugPage> {
  final SensorService _sensorService = SensorService();
  final LocationPermissionService _locationService = LocationPermissionService();
  bool _isListening = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
  }

  Future<void> _checkLocationPermissions() async {
    final status = await _locationService.checkLocationStatus();
    setState(() {
      _locationPermissionGranted = status.permissionGranted;
    });
  }

  @override
  void dispose() {
    _sensorService.dispose();
    super.dispose();
  }

  void _toggleSensorStream() async {
    final vehicleId = context.read<VehicleProvider>().vehicleId;
    if (vehicleId == null) {
      CustomSnackBar.showError(context, 'No vehicle selected! Please go to Garage and select a vehicle.');
      return;
    }
    if (!_isListening) {
      // Request location permission before starting
      final status = await _locationService.requestLocationAccess();
      setState(() {
        _locationPermissionGranted = status.permissionGranted;
      });

      if (!status.serviceEnabled) {
        _showLocationServiceDialog();
      }
    }

    setState(() {
      if (_isListening) {
        _sensorService.stop(context);
      } else {
        _sensorService.start(context: context);
      }
      _isListening = !_isListening;
    });
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            title: const Text('Location Services Disabled', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Location services are disabled. To use GPS features, please enable location services in your device settings.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileConstants.primaryBackground,
      body: StreamBuilder<SensorPacket>(
        stream: _sensorService.sensorStream,
        builder: (context, snapshot) {
          if (!_isListening) {
            return _buildInactiveState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildLoadingState();
          }

          return _buildDataView(snapshot.data!);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleSensorStream,
        backgroundColor: _isListening ? Colors.red : Colors.green,
        icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
        label: Text(_isListening ? 'STOP' : 'START'),
      ),
    );
  }

  Widget _buildInactiveState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 20),
          Text(
            'Sensor Stream Inactive',
            style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('Press START to begin streaming', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 20),
          Text('Initializing sensors...', style: TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          Text('Error', style: TextStyle(fontSize: 20, color: Colors.red[300], fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildDataView(SensorPacket packet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          _buildTimestampCard(packet.timestamp),
          const SizedBox(height: 16),

          // Raw Sensor Data Section
          _buildSectionHeader('Raw Sensor Data (Phone Coordinates)', Colors.blue),
          const SizedBox(height: 12),
          _buildRawDataSection(packet.raw),
          const SizedBox(height: 24),

          // Location Data Section
          _buildSectionHeader('Location / GPS Data', Colors.orange),
          const SizedBox(height: 12),
          _buildLocationSection(packet.location),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildTimestampCard(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.cyan, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Timestamp', style: TextStyle(fontSize: 12, color: Colors.white54)),
              Text(
                '${dateTime.hour}:${dateTime.minute}:${dateTime.second}.${dateTime.millisecond}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildRawDataSection(RawSensorData raw) {
    return Column(
      children: [
        _buildSensorCard('Accelerometer (with gravity)', Colors.blue, [
          _buildValueRow('ax', raw.ax, 'm/s²', Colors.blue[300]!),
          _buildValueRow('ay', raw.ay, 'm/s²', Colors.blue[400]!),
          _buildValueRow('az', raw.az, 'm/s²', Colors.blue[500]!),
        ]),
        const SizedBox(height: 12),
        _buildSensorCard('Linear Acceleration (without gravity)', Colors.lightBlue, [
          _buildValueRow('Ax', raw.Ax, 'm/s²', Colors.lightBlue[300]!),
          _buildValueRow('Ay', raw.Ay, 'm/s²', Colors.lightBlue[400]!),
          _buildValueRow('Az', raw.Az, 'm/s²', Colors.lightBlue[500]!),
        ]),
        const SizedBox(height: 12),
        _buildSensorCard('Gyroscope', Colors.cyan, [
          _buildValueRow('Gx', raw.Gx, 'deg/s', Colors.cyan[300]!),
          _buildValueRow('Gy', raw.Gy, 'deg/s', Colors.cyan[400]!),
          _buildValueRow('Gz', raw.Gz, 'deg/s', Colors.cyan[500]!),
        ]),
        const SizedBox(height: 12),
        _buildSensorCard('Magnetometer', Colors.indigo, [
          _buildValueRow('Mx', raw.Mx, 'µT', Colors.indigo[300]!),
          _buildValueRow('My', raw.My, 'µT', Colors.indigo[400]!),
          _buildValueRow('Mz', raw.Mz, 'µT', Colors.indigo[500]!),
        ]),
      ],
    );
  }

  Widget _buildLocationSection(LocationData location) {
    if (!location.hasLocation) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange[300], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Unavailable',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[300]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _locationPermissionGranted ? 'Waiting for GPS fix...' : 'Location permission not granted',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSensorCard('GPS Coordinates', Colors.orange, [
          _buildValueRow('Lat', location.latitude, '°', Colors.orange[300]!),
          _buildValueRow('Lon', location.longitude, '°', Colors.orange[400]!),
          _buildValueRow('Alt', location.altitude, 'm', Colors.orange[500]!),
        ]),
        const SizedBox(height: 12),
        _buildSensorCard('GPS Movement', Colors.deepOrange, [
          _buildValueRow('Spd', location.speed, 'm/s', Colors.deepOrange[300]!),
          _buildValueRow('Bear', location.bearing, '°', Colors.deepOrange[400]!),
          _buildValueRow('Acc', location.accuracy, 'm', Colors.deepOrange[500]!),
        ]),
      ],
    );
  }

  Widget _buildSensorCard(String title, MaterialColor color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, double value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value.toStringAsFixed(3),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
