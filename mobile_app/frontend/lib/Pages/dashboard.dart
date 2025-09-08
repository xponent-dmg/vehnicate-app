import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Pages/profile_page.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileConstants.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          // padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context),
                Consumer<UserProvider>(
                  builder:
                      (context, userProvider, child) => Text(
                        "Hey ${userProvider.currentUser?.name ?? 'there'} 👋",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                ),
                SizedBox(height: 24),
                // Start Card
                _startCard(context),
                SizedBox(height: 24),
                // Score and Car Info
                Row(
                  children: [
                    // Circular Score
                    _rpsScoreCard(context),
                    SizedBox(width: 16),
                    // Car Info
                    _selectedCarCard(context),
                  ],
                ),
                SizedBox(height: 24),
                // Weekly Challenge
                Container(
                  decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Drive smoothly',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF8E44AD).withAlpha(51),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Color(0xFF8E44AD), width: 1),
                            ),
                            child: Text(
                              'Weekly',
                              style: TextStyle(color: Color(0xFF8E44AD), fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Maintain constant acceleration for 50 km',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reward: 500 points', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('50%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(color: Color(0xFF3d3d54), borderRadius: BorderRadius.circular(3)),
                        child: Stack(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.5 * 0.5, // 50% of available width
                              height: 6,
                              decoration: BoxDecoration(
                                color: Color(0xFF8E44AD),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _header(context) {
  return Container(
    height: 90,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Leading section
        SizedBox(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 212, 161, 9),
                radius: 10,
                child: Icon(FontAwesomeIcons.centSign, size: 11),
              ),
              const SizedBox(width: 6),
              const Text('657', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),

        // Title section
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Vehnicate', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Calm in the Chaos', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),

        // Actions section
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF8E44AD),
            child: Transform.translate(offset: const Offset(0, 1.2), child: Image.asset("assets/logo.png")),
          ),
        ),
      ],
    ),
  );
}

Widget _textField({required String hintText, required IconData icon, required Color color}) {
  return Container(
    decoration: BoxDecoration(color: ProfileConstants.primaryBackground, borderRadius: BorderRadius.circular(12)),
    child: TextField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: color, size: 17),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(color: Colors.white),
    ),
  );
}

Widget _startCard(BuildContext context) {
  return Container(
    decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/map");
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: Color(0xFF8E44AD), borderRadius: BorderRadius.circular(25)),
                child: Text('START', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: Color(0xFF8E44AD), shape: BoxShape.circle),
              child: Icon(Icons.home, color: Colors.white, size: 20),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/imu");
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Color(0xFF3d3d54), shape: BoxShape.circle),
                child: Icon(Icons.sensors, color: Colors.white70, size: 20),
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: Color(0xFF3d3d54), shape: BoxShape.circle),
              child: Icon(Icons.more_horiz, color: Colors.white70, size: 20),
            ),
          ],
        ),
        SizedBox(height: 20),
        _textField(hintText: "Current location", icon: FontAwesomeIcons.locationCrosshairs, color: Color(0xFF8E44AD)),

        SizedBox(height: 12),
        _textField(hintText: 'Where to?', icon: FontAwesomeIcons.locationDot, color: Colors.white54),
      ],
    ),
  );
}

Widget _rpsScoreCard(BuildContext context) {
  final rpsScore = context.watch<UserProvider>().currentUser?.rpsScore;
  return Expanded(
    child: Container(
      height: 160,
      decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
      padding: EdgeInsets.all(20),
      child: CircularPercentIndicator(
        radius: 60,
        lineWidth: 10,
        percent: (rpsScore ?? 0) / 100,
        backgroundColor: ProfileConstants.darkPurple,
        progressColor: Color(0xFF8E44AD),
        circularStrokeCap: CircularStrokeCap.round, // rounded ends
        animation: true,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rpsScore?.toString() ?? '- -',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.5, vertical: 2.5),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF8E44AD)),
                borderRadius: BorderRadius.circular(10),
                color: Color(0xFF8E44AD).withAlpha(51),
              ),
              child: Text('RPS Score', style: TextStyle(color: Colors.white70, fontSize: 8)),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _selectedCarCard(BuildContext context) {
  return Expanded(
    child: Container(
      height: 160,
      decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
      padding: EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Consumer<VehicleProvider>(
                builder:
                    (context, vehicleProvider, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicleProvider.vehicleModel ?? 'No vehicle',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          vehicleProvider.vehicleRegistration ?? '------',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
              ),
              Spacer(),
              Column(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: Colors.white),
                  Text('30 km', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Color(0xFF3d3d54), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Icon(Icons.directions_car, color: Colors.white70, size: 30)),
            ),
          ),
        ],
      ),
    ),
  );
}
