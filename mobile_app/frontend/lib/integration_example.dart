// Example integration file showing how to add Drive Analysis to your app
// You can add this to your existing homepage.dart or create a new navigation file

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vehnicate_frontend/Pages/drive_analyze_page.dart';
import 'package:vehnicate_frontend/Pages/profile_page.dart';

class IntegrationExample extends StatelessWidget {
  const IntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF01010D), // Using your existing theme
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  'Vehnicate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Smart driving insights',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 40),

                // Drive Analysis Card
                _buildNavigationCard(
                  context: context,
                  title: 'Drive Analysis',
                  subtitle: 'Review your driving performance',
                  icon: FontAwesomeIcons.chartLine,
                  color: Color(0xFF765FD1),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DriveAnalyzePage())),
                ),

                SizedBox(height: 16),

                // Profile Card (existing)
                _buildNavigationCard(
                  context: context,
                  title: 'Profile',
                  subtitle: 'Manage your account settings',
                  icon: FontAwesomeIcons.user,
                  color: Color(0xFF9217BB),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage())),
                ),

                SizedBox(height: 16),

                // You can add more navigation items here
                _buildNavigationCard(
                  context: context,
                  title: 'Sensors',
                  subtitle: 'Real-time sensor data',
                  icon: FontAwesomeIcons.microchip,
                  color: Color(0xFF403862),
                  onTap: () {
                    // Navigate to your existing sensor pages
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to sensors')));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0E0E1A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Manrope', fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Manrope', fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: color, size: 16),
      ),
    );
  }
}
