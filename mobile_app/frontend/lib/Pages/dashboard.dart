import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/profile_page.dart';
import 'package:vehnicate_frontend/Screens/imu_collector_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                        ),
                        SizedBox(width: 8),
                        Text('657', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Vehnicate',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text('Calm in the Chaos', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage())),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF8E44AD), Color(0xFF9B59B6)]),
                        ),
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                // Greeting
                Text(
                  'Hey, Samprisha 👋',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 24),
                // Start Card
                Container(
                  decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ImuCollector()));
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Color(0xFF8E44AD),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                'START',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Color(0xFF8E44AD), shape: BoxShape.circle),
                            child: Icon(Icons.home, color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Color(0xFF3d3d54), shape: BoxShape.circle),
                            child: Icon(Icons.add, color: Colors.white70, size: 20),
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
                      Container(
                        decoration: BoxDecoration(color: Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(12)),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'current location',
                            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.location_on, color: Color(0xFF8E44AD), size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.swap_vert, color: Colors.white54, size: 16),
                          SizedBox(width: 8),
                          Text('Where to?', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(color: Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(12)),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Home',
                            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.home, color: Colors.white54, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Score and Car Info
                Row(
                  children: [
                    // Circular Score
                    Expanded(
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: 0.7,
                                    strokeWidth: 6,
                                    backgroundColor: Color(0xFF3d3d54),
                                    valueColor: AlwaysStoppedAnimation(Color(0xFF8E44AD)),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '70',
                                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                    ),
                                    Text('Your Score', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Car Info
                    Expanded(
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audi Q7',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text('TN10BY7079', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('30 km', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Container(
                                  width: 50,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF3d3d54),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.directions_car, color: Colors.white70, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
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
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xFF2d2d44),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Color(0xFF8E44AD), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.home, color: Colors.white, size: 24),
            ),
            Icon(Icons.location_on, color: Colors.white54, size: 24),
            Icon(Icons.directions_car, color: Colors.white54, size: 24),
            Icon(Icons.person, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }
}
