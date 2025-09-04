import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Pages/profile_page.dart';

class GaragePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with welcome text
                Text(
                  'Welcome to your Garage,',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Statistics Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('647', 'Miles Travelled'),
                    _buildStatCard('753', 'Credits Earned'),
                  ],
                ),
                const SizedBox(height: 30),

                // Vehicle Documentation Section
                Text(
                  'Vehicle Docs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                _buildDocumentTile('Registration Certificate', Icons.description),
                _buildDocumentTile('Vehicle Insurance', Icons.car_repair),
                _buildDocumentTile('PUC', Icons.eco),
                _buildDocumentTile('Driving License', Icons.card_membership),
                _buildDocumentTile('Personal Details', Icons.person),
                _buildDocumentTile('Owner Profile', Icons.account_circle),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        height: 80,
        decoration: BoxDecoration(color: Color(0xFF2d2d44), borderRadius: BorderRadius.all(Radius.circular(25))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, "/dash"),
              child: Row(
                children: [
                    Icon(Icons.home, color: Colors.white54, size: 24),
                ],
              ), 
            ),
            Icon(Icons.location_on, color: Colors.white54, size: 24),
            GestureDetector(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(0xFF8E44AD), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text("Garage", style: ProfileConstants.labelStyle),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, "/analyze"),
              child: Row(
                children: [
                    Icon(Icons.analytics, color: Colors.white54, size: 24),
                ],
              ), 
            ),
          ]
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.purple,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: () {
          // Handle navigation to document details
        },
      ),
    );
    
  }
}
