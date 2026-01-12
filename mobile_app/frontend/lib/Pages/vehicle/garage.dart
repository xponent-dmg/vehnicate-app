import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:vehnicate_frontend/Widgets/reveal_text.dart';
import 'package:vehnicate_frontend/Widgets/typewriter_text.dart';

class GaragePage extends StatelessWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LiquidPullToRefresh(
          onRefresh: () async {
            // Assuming VehicleProvider is defined and has a refresh method
            // and that this widget is within a Provider scope.
            // If not, you might need to adjust how VehicleProvider is accessed.
            await Provider.of<VehicleProvider>(context, listen: false).refresh();
          },
          color: Colors.black,
          backgroundColor: Colors.purple,
          showChildOpacityTransition: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _header(context),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                        if (!userProvider.isLoading && userProvider.currentUser != null) {
                        final firstName = userProvider.currentUser?.name?.split(' ').first ?? '';
                        return TypewriterText(
                          "Hey $firstName, welcome to your garage",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 24),
                  // Statistics Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_buildStatCard('647', 'Miles Travelled'), _buildStatCard('753', 'Credits Earned')],
                  ),
                  const SizedBox(height: 30),

                  // Vehicle Documentation Section
                  Text(
                    'Vehicle Docs',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  _buildDocumentTile(context, 'Registration Certificate', Icons.description),
                  _buildDocumentTile(context, 'Vehicle Insurance', Icons.car_repair),
                  _buildDocumentTile(context, 'PUC', Icons.eco),
                  _buildDocumentTile(context, 'Driving License', Icons.card_membership),
                ],
              ),
            ),
          ),
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
          Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          Navigator.pushNamed(context, '/document-upload', arguments: {'documentType': title});
        },
      ),
    );
  }
}


Widget _header(context) {
  return Container(
    height: 90,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title section
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF8E44AD).withAlpha(51),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF8E44AD), width: 1),
              ),
              child: Row(
                children: [
                    ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      "assets/vehnicate_logo_padded.png",
                      height: 32,
                      width: 32,
                    ),
                    ),
                    SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('vehnicate', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                      RevealText(
                        'calm in the chaos',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                        duration: Duration(milliseconds: 2000),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Actions section
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            customBorder: CircleBorder(),
            splashColor: Color(0xFF8E44AD).withOpacity(0.4),
            highlightColor: Color(0xFF8E44AD).withOpacity(0.2),
            child: Hero(
              tag: 'profile-avatar',
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF8E44AD),
                child: Transform.translate(offset: const Offset(0, 1.2), child: Image.asset("assets/logo.png")),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}