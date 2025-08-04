import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vehnicate_frontend/Pages/sensor_graph.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Vehnicate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sensor Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildSensorCard(
                    context,
                    title: "Accelerometer",
                    subtitle: "Monitor acceleration without gravity",
                    icon: Icons.trending_up,
                    color: Colors.blue,
                    onTap:
                        () => _navigateToPage(
                          context,
                          SensorGraph(
                            stream: userAccelerometerEventStream(),
                            title: "Accelerometer",
                            getX: (e) => e.x,
                            getY: (e) => e.y,
                            getZ: (e) => e.z,
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildSensorCard(
                    context,
                    title: "Gyroscope",
                    subtitle: "Track device rotation and orientation",
                    icon: Icons.screen_rotation_outlined,
                    color: Colors.green,
                    onTap:
                        () => _navigateToPage(
                          context,
                          SensorGraph(
                            stream: gyroscopeEventStream(),
                            title: "Gyroscope",
                            getX: (e) => e.x,
                            getY: (e) => e.y,
                            getZ: (e) => e.z,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}
